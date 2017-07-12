/*
 * File:         phantom_api.c
 *
 * Project:      PHANTOM
 *
 * Organisation: University of York
 *
 * Author(s):    A. Moulds
 *
 * Version:      0.11 (dev only)
 *
 * Description:
 *
 * Copyright:    University of York. 2017.
 *
 * Legal:        All rights reserved. No warranty, explicit or implicit, provided.
 *
 * Revisions:
 * 	0.10 		Initial.
 * 	0.11		Changes:
 * 				1. Added phantom_initialise(). Moved core mapping code to end of fn.
 * 				2. corrected behaviour of phantom_fpga_configure().
 * 				3. Added phantom_get_version() fn.
 *
 *
 *
 *
*/



/*
 *                        ============ TO DO LIST ============
 *
 **********************************************************************************************
 *
 *  1. Add interrupt handling support (call backs etc.)
 *  2. Code to read bitfile header to we can check top-level design name and FPGA device p/n.
 *  3. Add DMA support (where useful).
 *
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/sendfile.h>
#include <sys/stat.h>
#include <errno.h>
#include <sys/mman.h>
#include <unistd.h>
#include <dirent.h>
#include "phantom_api.h"
#include "phantom_api_lowlevel.h"
#include "phantom_xml_parser.h"


/* set API version number MAJOR.MINOR */
static char version_num[5] = "0.11";



/*
 * Fn to return string containing current API version.
 * Parameters:
 *    none
 * Return:
 *    array of chars
 *
 */
char *phantom_get_version(void)
{
	return version_num;
}


/*
 * phantom_download() function copies a supplied PHANTOM platform file to the target hardware.
 * The file must be in compressed gzip tar (tar.gz)  format. The function first downloads the
 * file to the target’s SD card, then uncompresses and extract the archive to create a dedicated
 * fixed file structure used later to initialise the API and configure PHANTOM platform.
 *
 * Parameters:
 * int phantom_platform_fd  - a file descriptor to an open *.tar.gz file.
 *
 * Return Value:
 *    PHANTOM_OK    - if download successful.
 *    PHANTOM_ERROR - if system error occurred (e.g. error in file handling).
 */
int phantom_download(int phanom_platform_fd)
{
	char cmd[200];
    int sdcard_fd;
    struct stat filestat;
    int ret;
    off_t fsize;

    //
    // copy opened file to SD card
    if(phanom_platform_fd < 0)
    {
        #ifdef DEBUG
    	    printf("error: invalid file descriptor!\n");
        #endif
        return PHANTOM_ERROR;
    }
    fstat(phanom_platform_fd, &filestat);
    fsize = filestat.st_size;

    sdcard_fd = open(SD_CARD_PHANTOM_DOWNLOAD_FILE, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR);
    if(sdcard_fd < 0)
    {

        #ifdef DEBUG
    	    perror("api error");
        #endif
        return PHANTOM_ERROR;
    }
    ret = sendfile(sdcard_fd, phanom_platform_fd, NULL, fsize);
    close(sdcard_fd);

    if (ret < 0)
    {
        #ifdef DEBUG
    	    perror("api error");
        #endif
        return PHANTOM_ERROR;
    }

    // remove existing fpga directory (for consistancy!)
	sprintf(cmd, "rm -Rf %s", SD_CARD_PHANTOM_FPGA_LOC);
    system(cmd);

	// uncompress and extract archive phantom_fpga.tar.gz
    memset(cmd, '\0', 200);
	sprintf(cmd, "tar -xz -C %s -f %s", SD_CARD_PHANTOM_LOC, SD_CARD_PHANTOM_DOWNLOAD_FILE);
	system(cmd);

    return PHANTOM_OK;
}



/*
 * The phantom_initialise() function is responsible for initialising the API with configuration data
 * downloaded after a successful phantom_download() call. The function maps all found core components
 * to user (virtual memory) space.
 *
 * Parameters:
 *    none.
 *
 * Return Value:
 *    PHANTOM_OK     - if initialisation successful.
 *    PHANTOM_ERROR  - if initialisation unsuccessful.
 */
int phantom_initialise()
{
	FILE *xml_fp;
	int num_ph_comps;
	phantom_ip_t *phantom_ipcores_ptr;
	phantom_platform_info_t* ph_platform;

	/* attempt to open phantom_fpga_conf.xml file. */
	if((xml_fp = fopen(SD_CARD_PHANTOM_FPGA_CONF_FILE, "r"))==NULL)
	{
		#ifdef DEBUG
			printf("error: unable to open fpga_conf.xml file\n");
			perror("api error");
		#endif
		return PHANTOM_ERROR;
	}

    /* init API from downloaded xml */
	if(phantom_conf(xml_fp))
	{
		fclose(xml_fp);
		#ifdef DEBUG
			printf("phantom_conf() error\n");
		#endif
		return PHANTOM_ERROR;

	}
	fclose(xml_fp);

    /* Ensure the target board required by the FPGA design matches the running platform */
	ph_platform = phantom_platform_get_info();
	if(strcmp(ph_platform->platform, "generic") && strcmp(ph_platform->platform, TARGET_BOARD))
	{
		#ifdef DEBUG
			printf("error: mismatch in target platform. Requesting %s.\n", ph_platform->platform);
		#endif
		return PHANTOM_ERROR;
	}

    /* Ensure the target fpga type required by the design matches the running platform's fpga */
	if(strcmp(ph_platform->fpga_type, TARGET_FPGA))
	{
		#ifdef DEBUG
			printf("error: mismatch in target fpga type. Requesting %s.\n", ph_platform->fpga_type);
		#endif
		return PHANTOM_ERROR;
	}

	/* map core components to user space (virtual memory) */
	if(open_devs())
	{
		#ifdef DEBUG
			printf("error: open_devs() failed\n");
		#endif
		close_devs();
		return PHANTOM_ERROR;
	}
	if((num_ph_comps = phantom_fpga_get_num_ips()) < 0)
		return PHANTOM_ERROR;
    phantom_ipcores_ptr = phantom_fpga_get_ips();
    unmap_devs();
    for(int i = 0; i < num_ph_comps; i++)
    {
       if(map_component(phantom_ipcores_ptr))
    		   return PHANTOM_ERROR;
       phantom_ipcores_ptr++;
    }

    return PHANTOM_OK;
}



/*
 * A call to phantom_fpga_configure_reset() causes the configured platform FPGA to be reset,
 * i.e. the FPGA’s PL configuration bits are cleared.  The FPGA is then left in an unprogrammed
 * state. The function checks the FPGA’s DONE pin is low on return.
 *
 * Parameters:
 *    none.
 *
 * Return Value
 *    PHANTOM_OK     - if reset completed.
 *    PHANTOM_FALSE  - if reset unsuccessful.
 */
int phantom_fpga_configuration_reset()
{
    if(fpga_config_reset())
        return PHANTOM_FALSE;

    return PHANTOM_OK;
}



/*
 * A call to phantom_fpga_is_done() will return the state of the platform FPGA’s DONE pin. Use
 * this function to determine if the FPGA has been programmed successfully.
 *
 * Parameters:
 *    None.
 *
 * Return Value:
 *    PHANTOM_OK      - if DONE pin high (FPGA configured).
 *    PHANTOM_FALSE   - if DONE pin low (FPGA not configured).
 *    PHANTOM_ERROR   - system error.
 */
int phantom_fpga_is_done()
{
    char str[81];

    if(get_file_str(FPGA_DONE_FILE, str))
        return PHANTOM_ERROR;

    if (strcmp(str,"1"))
        return PHANTOM_FALSE;

    return PHANTOM_OK;
}



/*
 * The phantom_fpga_configure() function fetches the bitfile stored in the PHANTOM platform fs
 * (on the platform’s SD card) and uses it to configure the FPGA. The function examines
 * the bitfile to ensure it is compatible with the FPGA device specified in the XML conf
 * file in the PHANTOM fs. TBD. The function finally checks the FPGA’s DONE pin is asserted on return.
 *
 * Parameters:
 *    None.
 *
 * Return Value:
 *   PHANTOM_OK      - if configration successful.
 *   PHANTOM_FALSE   - if configuration failed.
 */
int phantom_fpga_configure(void)
{
    int xdevcfg_fd;
    struct stat filestat;
    int ret;
    off_t size;
    int bitfile_fd;
    char bitfile_name[200];
    phantom_platform_info_t *ph_hwinfo;

    ph_hwinfo = get_phantom_platform_info();
    sprintf(bitfile_name, "%s%s", SD_CARD_PHANTOM_FPGA_BITFILE_LOC, ph_hwinfo->bitfile);
    bitfile_fd = open(bitfile_name, O_RDONLY);
    if(bitfile_fd < 0)
    {
		#ifdef DEBUG
    		printf("error: can't open bitfile %s\n", bitfile_name);
		#endif
        return PHANTOM_ERROR;
    }

    fstat(bitfile_fd, &filestat);
    size = filestat.st_size;

    xdevcfg_fd = open(FPGA_CFG_FILE, O_WRONLY);
    if(xdevcfg_fd < 0)
    {
    	close(bitfile_fd);
        return PHANTOM_ERROR;
    }

    ret = sendfile(xdevcfg_fd, bitfile_fd, NULL, size);
    close(xdevcfg_fd);
	close(bitfile_fd);

    if (ret < 0)
        return PHANTOM_FALSE;

    return phantom_fpga_is_done();
}



/*
 * The phantom_fpga_reset() function issues a specific reset on one or more of
 * the FPGA’s FCLKRESETN[3:0] asynchronous reset lines. The function causes the reset line
 * to assert for 100 ns before auto-deasserting, i.e. the line is pulsed.
 *
 * Parameters:
 *    uint8_t fpga_plreset  - acceptible values from fclkresetn_type_t type, i.e.
 *                            FCLKRESETN0, FCLKRESETN1, FCLKRESETN2 and FCLKRESETN3.
 *
 * Return Value:
 *    PHANTOM_OK     - if resets successfully applied.
 *    PHANTOM_FALSE  - failed to issue reset.
 */
int phantom_fpga_reset(const uint8_t fpga_plreset)
{

	if (fpga_plreset & ~(FCLKRESETN3 | FCLKRESETN2 | FCLKRESETN1 | FCLKRESETN0))
		return PHANTOM_FALSE;

	if (fpga_reset(fpga_plreset))
		return PHANTOM_FALSE;

    return PHANTOM_OK;
}



/*
 * The phantom_fpga_reset_global() function issues a reset on all four FPGA FCLKRESETN[3:0]
 * lines simultaneously. The function causes the reset lines to assert for 100 ns before
 * auto-deasserting, i.e. the lines are pulsed.
 *
 * Parameters
 *    None.
 *
 * Return Value
 *    PHANTOM_OK     - if resets successfully applied.
 *    PHANTOM_FALSE  - failed to issue resets.
 */
int phantom_fpga_reset_global(void)
{
	if (fpga_reset(FCLKRESETN3 | FCLKRESETN2 | FCLKRESETN1 | FCLKRESETN0))
		return PHANTOM_FALSE;

    return PHANTOM_OK;
}



/*
 * The phantom_fpga_get_num_ips() function returns the number of PHANTOM IP cores (components)
 * existing in the current downloaded PHANTOM platform. The number is calculated during a call
 * to phantom_initialise().
 *
 * Parameters:
 *    None.
 *
 * Return Value:
 *    int value containing number of IP cores;
 *    returns -1 if number of IP cores exceeds MAX_PHANTOM_COMPONENTS.
*/
int phantom_fpga_get_num_ips()
{
    return get_phantom_component_count();
}



/*
 * The function phantom_fpga_get_ips() returns a pointer to the array of structs describing the
 * IP cores (components) in the downloaded PHANTOM platform. The array is populated during the
 * call to phantom_initialise(). If no components were found, the array is empty.
 *
 * Parameters:
 *    None.
 *
 * Return Value:
 *    phantom_ip_t pointer to start of array of phantom_ip_t structs.
 */
phantom_ip_t *phantom_fpga_get_ips()
{
	return get_phantom_component_array();
}


/*
 * After a call to phantom_initialise() this function will return a populated struct with details of the
 * PHANTOM component specified in idx. Note: an idx value of 0 points to the first component in the maintained array.
 * Parameter:
 *    idx - index of struct array
 * Return:
 *    struct from indexed array of structs.
 *
 */
phantom_ip_t *phantom_fpga_get_ip_from_idx(const uint8_t idx)
{
	return get_phantom_component(idx);
}



/*
 * After a call to phantom_initialise() this function will return a populated struct with the given Phantom component id.
 * Parameters:
 *     id - id number of requested core
 * Return:
 *     struct of specified core on success, else NULL.
 *
 */
phantom_ip_t *phantom_fpga_get_ip(const uint8_t id)
{
	phantom_ip_t* ip_ptr;
	for(uint8_t i = 0; i < MAX_PHANTOM_COMPONENTS; i++)
	{
		ip_ptr = get_phantom_component(i);
		if(ip_ptr->id == id)
			return ip_ptr;
	}
	return NULL;
}



/*
 * After a call to phantom_initialise() this function will return a populated struct with the given Phantom component idstring.
 * Parameters:
 *     idstr - id string of requested core
 * Return:
 *     struct of specified core on success, else NULL.
 *
 */
phantom_ip_t *phantom_fpga_get_ip_from_idstr(const char *idstr)
{
	phantom_ip_t* ip_ptr;
	for(uint8_t i = 0; i < MAX_PHANTOM_COMPONENTS; i++)
	{
		ip_ptr = get_phantom_component(i);
		if(!strcmp(ip_ptr->idstring, idstr))
			return ip_ptr;
	}
	return NULL;
}



/*
 * After a call to phantom_initialise() this function will return a populated struct with the given Phantom component ip name.
 * Parameters:
 *     idstr - id string of requested core
 * Return:
 *     first struct found of specified core on success, else NULL.
 *
 */
phantom_ip_t *phantom_fpga_get_ip_from_name(const char *ipname)
{
	phantom_ip_t* ip_ptr;
	for(uint8_t i = 0; i < MAX_PHANTOM_COMPONENTS; i++)
	{
		ip_ptr = get_phantom_component(i);
		if(!strcmp(ip_ptr->ipname , ipname))
			return ip_ptr;
	}
	return NULL;
}



/*
 * Starts the specified IP core. Has no effect if the core is already started.
 * Parameters
 *    ip – The IP core to control.
 * Returns PHANTOM_OK if the core started successfully, or PHANTOM_ERROR if not.
 * Note: slave s0 must be assigned to IP core control registers.
 *
 */
int phantom_fpga_ip_start(phantom_ip_t* ip)
{
	phantom_data_t reg = reg_read(ip->s0_vmem_base, IPCORE_CTRL_ADDR);
	reg_write(ip->s0_vmem_base, IPCORE_CTRL_ADDR, reg | IPCORE_CTRL_AP_START_BM);

    return PHANTOM_OK;
}



/*
 * Sets the IP core to automatically restart when its ap_done signal is asserted.
 * Parameters
 *    ip – The IP core to control.
 * Returns PHANTOM_OK if the core started successfully, or PHANTOM_ERROR if not.
 * Note: slave s0 must be assigned to IP core control registers.
 *
 */
int phantom_fpga_ip_set_autorestart(phantom_ip_t* ip)
{
	phantom_data_t reg = reg_read(ip->s0_vmem_base, IPCORE_CTRL_ADDR);
	reg_write(ip->s0_vmem_base, IPCORE_CTRL_ADDR, reg | IPCORE_CTRL_AUTORESTART_BM);

    return PHANTOM_OK;
}


/*
 * Stops the IP core from automatically restarting when its ap_done signal is asserted.
 * Parameters
 *    ip – The IP core to control.
 * Returns PHANTOM_OK if the core started successfully, or PHANTOM_ERROR if not.
 * Note: slave s0 must be assigned to IP core control registers.
 *
 */
int phantom_fpga_ip_clear_autorestart(phantom_ip_t* ip)
{
	phantom_data_t reg = reg_read(ip->s0_vmem_base, IPCORE_CTRL_ADDR);
	reg_write(ip->s0_vmem_base, IPCORE_CTRL_ADDR, reg & ~IPCORE_CTRL_AUTORESTART_BM);

    return PHANTOM_OK;
}





/*
 * Checks if the specified IP has completed its execution.
 * Parameters
 *    ip (phantom_ip_t*) – The IP core to query.
 * Returns PHANTOM_OK if the core stopped successfully, or PHANTOM_FALSE if not.
 * Note: slave s0 must be assigned to IP core control registers.
 *
 */
int phantom_fpga_ip_is_done(phantom_ip_t* ip)
{
	if(reg_read(ip->s0_vmem_base, IPCORE_CTRL_ADDR) & IPCORE_CTRL_AP_DONE_BM)
		return PHANTOM_OK;
	return PHANTOM_FALSE;
}



/*
 * Checks if the specified IP is idle and ready for I/O or to be started.
 * Parameters
 *    ip (phantom_ip_t*) – The IP core to query.
 * Returns PHANTOM_OK if the core is idle, or PHANTOM_FALSE if not.
 * Note: slave s0 must be assigned to IP core control registers.
 *
 */
int phantom_fpga_ip_is_idle(phantom_ip_t* ip)
{
	if(reg_read(ip->s0_vmem_base, IPCORE_CTRL_ADDR) & IPCORE_CTRL_AP_IDLE_BM)
		return PHANTOM_OK;
	return PHANTOM_FALSE;

}



/*
 * Set a value inside one of two AXI slave address spaces of the IP. addr is based from 0 and will be automatically
 * offset to the appropriate base address (phantom_ip_t.base_address).
 * Parameters
 *    ip (phantom_ip_t*) – The IP core to query.
 *    addr (phantom_address_t) – The address, based at 0, inside the address space of
 *    the IP core.
 *    val (phantom_data_t) – The value to set.
 *    axi_slave - slave number: 0 = s0 axi slave, 1 = s1 axi slave.
 * Returns PHANTOM_OK if the value was set, or PHANTOM_ERROR if not.
 *
 *
 */
int phantom_fpga_ip_set(phantom_ip_t* ip, phantom_address_t addr, phantom_data_t val, uint8_t axi_slave)
{
	switch (axi_slave)
	{
		case 0:
			if(addr >= ip->s0_axi_address_size)
				return PHANTOM_ERROR;
			reg_write(ip->s0_vmem_base, addr, val);
			break;
		case 1:
			if(addr >= ip->s1_axi_address_size)
				return PHANTOM_ERROR;
			reg_write(ip->s1_vmem_base, addr, val);
			break;
		default:
			return PHANTOM_ERROR;
	}

	return PHANTOM_OK;
}



/*
 * Get a value from the AXI Slave address space of the IP. addr is based from 0 and will be automatically
 * offset to the appropriate base address (phantom_ip_t.base_address).
 * Parameters
 *    ip (phantom_ip_t*) – The IP core to query.
 *    addr (phantom_address_t) – The address, based at 0, inside the address space of the IP core.
 * Returns The value of the argument specified by addr.
 * Note: if the AXI bus stalls this function will hang.
 *
 */
phantom_data_t phantom_fpga_ip_get(phantom_ip_t* ip, const phantom_address_t addr, const uint8_t axi_slave)
{
	switch (axi_slave)
	{
		case 0:
			if(addr >= ip->s0_axi_address_size)
				return 0;
			return reg_read(ip->s0_vmem_base, addr);
			break;
		case 1:
			if(addr >= ip->s1_axi_address_size)
				return 0;
			return reg_read(ip->s1_vmem_base, addr);
			break;
		default:
			return 0;
	}
}



/*
 * Function to return details of Phantom platform hardware.
 * Parameters:
 *     none
 * Return:
 *     struct defining hardware platform
 *
 */
phantom_platform_info_t *phantom_platform_get_info()
{
	return get_phantom_platform_info();
}


/*
 * Clean-up API.
 * Parameters:
 *    None
 * Return Value:
 *    None
 *
 */
void phantom_terminate(void)
{
	unmap_devs();
	close_devs();
}




