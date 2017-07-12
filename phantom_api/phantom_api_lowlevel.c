/*
 * File:         phantom_api_lowlevel.c
 *
 * Project:      PHANTOM
 *
 * Organisation: University of York
 *
 * Author(s):    A. Moulds
 *
 * Version:      0.1 (dev only)
 *
 * Description:  Low-level private functions written to support the Phantom API.
 *
 * Copyright:    University of York. 2017.
 *
 * Legal:        All rights reserved. No warranty, explicit or implicit, provided.
 *
 * Revisions:
 *
 * Notes:        The funcions coded in this source file are private to phatom_api only and are
 *               intended to be hidden from the user. DO NOT MAKE PUBLIC.
 *
 *
*/



#include "phantom_api.h"
#include "phantom_api_lowlevel.h"
#include "phantom_xml_parser.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <errno.h>




typedef struct {
	int fd;
	uint8_t flags;
} uio_struct_t;



/* struct to hold all uio device file descriptors */
static uio_struct_t uio[NUM_OF_UIO_DEVS];



/* Private Functions prototype */
int get_mapped_vmem_base(uint32_t **, phantom_address_t, uint32_t);
unsigned int get_memory_size(char *);
char* get_nodestr(const char *);
int check_for_node_str(const char*, const char*);
int check_valid_addr_and_size(phantom_address_t, uint32_t);




/*
 * Function to open all phantom uio nodes, ready for mapping. If unsuccessful, it
 * will try to automatically load phantom module (assumes not loaded) and repeat
 * attempt for uioxx access.
 */
int open_devs()
{
	char bufstr[LINE_LEN];
	extern uio_struct_t uio[];
	int err = 0;

	for(uint8_t i=0; i < NUM_OF_UIO_DEVS; i++)
	{
		if(~(uio[i].flags & UIO_DEV_OPENED))
		{
			sprintf(bufstr, "%s%d", UIO_DEVS_LOC, i);
			uio[i].fd  = open(bufstr, O_RDWR);
			if (uio[i].fd < 0)
				err = -1;
			else
				uio[i].flags = UIO_DEV_OPENED;
		}
	}
	if(!err)
		return 0;

	/* have error so try loading phantom module */
	#ifdef DEBUG
		printf("uio devs not open so loading module manually...\n");
	#endif
	close_devs();
	sprintf(bufstr, "modprobe %s\n", PHANTOM_MODULE);
	system(bufstr);
	sleep(1); // wait enough time to ensure kernel has loaded all uio modules

	/* repeat attempt to open uio nodes */
	err = 0;
	for(uint8_t i=0; i < NUM_OF_UIO_DEVS; i++)
	{
		sprintf(bufstr, "%s%d", UIO_DEVS_LOC, i);
		uio[i].fd  = open(bufstr, O_RDWR);
		if (uio[i].fd < 0)
		{
			#ifdef DEBUG
			printf("failed to open %s\n",bufstr);
			#endif
			err = -1;
		}
		else
			uio[i].flags = UIO_DEV_OPENED;
	}
	return err;
}



/*
 * close all opened uio nodes
 */
void close_devs(void)
{
	for(uint8_t i=0; i < NUM_OF_UIO_DEVS; i++)
	{
		if(uio[i].flags & UIO_DEV_OPENED)
		{
			close(uio[i].fd);
			uio[i].flags = 0; // clear all flags
		}
	}
}



/*
 * Un-map all memory mapped uio devices.
 */
void unmap_devs(void)
{
	phantom_ip_t *ph_ipcores_ptr = get_phantom_component_array();
	uint8_t num_comps = get_phantom_component_count();
	for(int i=0; i < num_comps; i++)
	{
		if(ph_ipcores_ptr->s0_vmem_base != NULL) {
			if(munmap((void*) ph_ipcores_ptr->s0_vmem_base, ph_ipcores_ptr->s0_axi_address_size)) {
				#ifdef DEBUG
					printf("error: unable to unmap vm region\n");
				#endif
			}
			ph_ipcores_ptr->s0_vmem_base = NULL;
		}
		if(ph_ipcores_ptr->s1_vmem_base != NULL) {
			if(munmap((void*) ph_ipcores_ptr->s0_vmem_base, ph_ipcores_ptr->s1_axi_address_size)) {
				#ifdef DEBUG
					printf("error: unable to unmap vm region\n");
				#endif
			}
			ph_ipcores_ptr->s1_vmem_base = NULL;
		}


		ph_ipcores_ptr++;
	}
}



/* Search opened uioxx node for address base and size match and map in to virtual memory.
 * Returns matched uio fd.
 * Note: each uio node can only be mapped once.
 * Note: zynq ultrascale PS is 32-bit only so need to workout scheme for 64-bit PL address space mapping. TBD.
 */
int get_mapped_vmem_base(uint32_t **mmem, phantom_address_t axi_base_addr, uint32_t axi_addr_size)
{
	char bufstr[LINE_LEN];
	char valstr[LINE_LEN];
	phantom_address_t tmp;
	extern uio_struct_t uio[];

	/* search for base address match in uio pool and if found map */
	for(int i=0; i < NUM_OF_UIO_DEVS; i++)
	{
		sprintf(bufstr,"%suio%d%s", SYSCLASS_LOC, i, MAP_ADDR_FILE); // get map0/addr value for opened uioxx
		if(get_file_str(bufstr, valstr))
		{
			#ifdef DEBUG
				printf("failed to open %s\n",bufstr);
			#endif
			return -1;
		}
		sscanf(valstr,"%x", &tmp);
		if(tmp == axi_base_addr)
		{
			if(uio[i].flags & UIO_DEV_MAPPED)
			{
				#ifdef DEBUG
					printf("error: unable to map uio[%d] - it's already mapped!\n",i);
				#endif
				return -1;
			}
		    if((*mmem = mmap(NULL, axi_addr_size, PROT_READ | PROT_WRITE, MAP_SHARED, uio[i].fd, 0)) == MAP_FAILED)
		    {
				#ifdef DEBUG
					printf("error: failed to map uio%d\n", i);
					perror("error:");
				#endif
				*mmem = NULL;
		    	return -1;
		    }
			uio[i].flags |= UIO_DEV_MAPPED;
		    return 0;
		}
	}
	return -1; // failed
}



int check_valid_addr_and_size(phantom_address_t base_addr, uint32_t addr_size)
{

	if((base_addr < AXI_GP0_BASEADDR) || (base_addr >= MAX_AXI_GP1_BASEADDR))
	{
		#ifdef DEBUG
			printf("error: invalid axi bus slave address 0x%08x\n",base_addr);
		#endif
		return -1;
	}
	if((base_addr > MAX_AXI_GP0_BASEADDR) && (base_addr < AXI_GP1_BASEADDR))
	{
		#ifdef DEBUG
			printf("error: invalid axi bus slave address 0x%08x\n",base_addr);
		#endif
		return -1;
	}
	if (addr_size > AXI_GP_ADDR_RANGE)
	{
		#ifdef DEBUG
			printf("error: axi bus slave address range too high @ 0x%08x\n",addr_size);
		#endif
		return -1;
	}
	return 0;
}



/*
 * Function maps given phantom core in to user space memory.
 */
int map_component(phantom_ip_t *ph_ipcore_ptr)
{
	extern uio_struct_t uio[];

	ph_ipcore_ptr->s0_vmem_base = NULL;
	ph_ipcore_ptr->s1_vmem_base = NULL;

	if(ph_ipcore_ptr->s0_axi_base_address != 0) // a zero address indicates unused so ignore
	{
		if(check_valid_addr_and_size(ph_ipcore_ptr->s0_axi_base_address, ph_ipcore_ptr->s0_axi_address_size))
			return -1;
		if(get_mapped_vmem_base(&ph_ipcore_ptr->s0_vmem_base, ph_ipcore_ptr->s0_axi_base_address, ph_ipcore_ptr->s0_axi_address_size))
			return -1;
	}
	if(ph_ipcore_ptr->s1_axi_base_address != 0) // a zero address indicates unused so ignore
	{
		if(check_valid_addr_and_size(ph_ipcore_ptr->s1_axi_base_address, ph_ipcore_ptr->s1_axi_address_size))
			return -1;
		if(get_mapped_vmem_base(&ph_ipcore_ptr->s1_vmem_base, ph_ipcore_ptr->s1_axi_base_address, ph_ipcore_ptr->s1_axi_address_size))
			return -1;
	}
}



int fpga_reset(uint8_t plreset)
{
    int memfd;
    phantom_address_t *mapped_base;
    phantom_data_t fpga_rst;

    fpga_rst = 0U;
    fpga_rst |= plreset;

	/* open mem device for slcr registers access */
    memfd = open("/dev/mem", O_RDWR | O_SYNC);
    mapped_base = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, memfd, SLCR_BASE_ADDR);
    if(mapped_base == MAP_FAILED)
    	return -1;

    /* pulse reset signal for 100 ns */
    reg_write(mapped_base, SLCR_FPGA_RST_CTRL_REG, fpga_rst);
    nanosleep((const struct timespec[]){{0, 100L}}, NULL);
    reg_write(mapped_base, SLCR_FPGA_RST_CTRL_REG, 0);

    close(memfd);
	return 0;

}



void reg_write(void *reg_base, phantom_address_t offset, phantom_data_t value)
{
	*((volatile phantom_address_t *)(reg_base + offset)) = value;
}



phantom_data_t reg_read(void *reg_base, phantom_address_t offset)
{
	return *((volatile phantom_address_t *)(reg_base + offset));
}



unsigned int get_memory_size(char *sysfs_path_file)
{
	FILE *size_fp;
	uint32_t size;

	/* open the file that describes the memory range size that is based on the
	 * reg property of the node in the device tree */
	size_fp = fopen(sysfs_path_file, "r");
	if (size_fp == NULL) {
		#ifdef DEBUG
			printf("error: unable to open the uio size file\n");
		#endif
		return -1;
	}

	/* get the size which is an ASCII string such as 0xXXXXXXXX and then be stop
	 * using the file */
	fscanf(size_fp, "0x%08X", &size);
	fclose(size_fp);
	return size;
}



char* get_nodestr(const char *sysfs_path_file)
{
	FILE *name_fp;
	static char name[256];

	name_fp = fopen(sysfs_path_file, "r");
	if (name_fp == NULL) {
		#ifdef DEBUG
			printf("api error: unable to open file\n");
		#endif
		return NULL;
	}

	fscanf(name_fp, "%s", name);
	fclose(name_fp);
	return name;
}



int check_for_node_str(const char* nodestr, const char* checkstr)
{
	char str[256];

	strcpy(str, get_nodestr(nodestr));
	if (strcmp(str, checkstr))
	{
		return -1;
	}
	return 0;

}



int get_file_str(char *sysfs_path_file, char* str)
{
	FILE *fp;

	fp = fopen(sysfs_path_file, "r");
	if (fp == NULL)
		return -1;

	fscanf(fp,"%s",str);
	fclose(fp);
	return 0;
}



/*
 * Function to reset (clear) the FPGA PL configuration. This will cause the DONE pin to de-assert low.
 * NOTE: THIS FUNCTION IS NOT ATOMIC.
 * Parameters: none
 * Return: 0 on success, -1 on fail.
 */
int fpga_config_reset()
{
    int memfd;
    phantom_address_t *mapped_base;
    phantom_data_t ctrl_reg;
    phantom_data_t status_reg;
    int i;


	/* open mem device for devcfg access */
    memfd = open("/dev/mem", O_RDWR | O_SYNC);
    mapped_base = mmap(NULL, 0x100, PROT_READ | PROT_WRITE, MAP_SHARED, memfd, DEVCFG_BASE_ADDR);

    /* get current devcfg.ctrl value */
    ctrl_reg = reg_read(mapped_base, DEVCFG_CTRL_REG);

    /* ensure PROG_B high (should be by default) */
    ctrl_reg |= PCFG_PROG_B_MASK;
    reg_write(mapped_base, DEVCFG_CTRL_REG, ctrl_reg);

    /* set PROG_B low */
    ctrl_reg &= ~PCFG_PROG_B_MASK;
    reg_write(mapped_base, DEVCFG_CTRL_REG, ctrl_reg);

    /* wait until PCAP_INT status bit is low (reset state). Use timeout to prevent stall on error. */
    for(i=0; i < REG_READ_TIMEOUT; i++)
    {
    	status_reg = reg_read(mapped_base, DEVCFG_STATUS_REG);
    	if ((status_reg & PCFG_INIT_MASK)==0)
    		break;
    	usleep(1);
    }
    if (i==REG_READ_TIMEOUT)
    {
        close(memfd);
        return -1;

    }

    /* return PROG_B high */
    ctrl_reg |= PCFG_PROG_B_MASK;
    reg_write(mapped_base, DEVCFG_CTRL_REG, ctrl_reg);

    /* wait until PCAP_INT returns high (set state) */
    for(i=0; i < REG_READ_TIMEOUT; i++)
    {
    	status_reg = reg_read(mapped_base, DEVCFG_STATUS_REG);
    	if (status_reg & PCFG_INIT_MASK)
    		break;
    	usleep(1);
    }
    if (i==REG_READ_TIMEOUT)
    {
        close(memfd);
        return -1;

    }

    close(memfd);
	return 0;
}


