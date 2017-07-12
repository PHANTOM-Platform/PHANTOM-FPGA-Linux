/*
 * File:         phantom_api_lowlevel.h
 *
 * Project:      PHANTOM
 *
 * Organisation: University of York
 *
 * Author(s):    A. Moulds
 *
 * Version:      0.1 (dev only)
 *
 * Description:
 *
 * Copyright:    University of York. 2017.
 *
 * Legal:        All rights reserved. No warranty, explicit or implicit, provided.
 *
 * Revisions:
 *
 *
 *
 *
*/




#ifndef _PHANTOM_API_LOWLEVEL_H
#define _PHANTOM_API_LOWLEVEL_H



#include "phantom_api.h"


/*
 * Board Specifics Defs.
 */

#if PHANTOM_HW_PLATFORM == MICROZED // defined in phantom_api.h
	#define TARGET_BOARD "microzed"
    #define SD_CARD_PHANTOM_LOC "/run/media/mmcblk0p1/phantom/"
#elif PHANTOM_HW_PLATFORM == ZC706
	#define TARGET_BOARD "zc706"
    #define SD_CARD_PHANTOM_LOC "/run/media/mmcblk0p1/phantom/" // NOT KNOWN. TBD
#elif PHANTOM_HW_PLATFORM == ZEBO
	#define TARGET_BOARD "zebo"
    #define SD_CARD_PHANTOM_LOC "/run/media/mmcblk0p1/phantom/" // NOT KNOWN. TBD
#endif

#if FPGA == ZYNQ_APSOC
	#define TARGET_FPGA "zynq_apsoc"
#elif FPGA == ZYNQ_MPSOC
	#define TARGET_FPGA "zynq_mpsoc"
#endif


/*
 * Defines
 */

#define NUM_OF_UIO_DEVS 32

#define DEFAULT_MEM_SIZE 0x1000

#define UIO_DEVS_LOC "/dev/uio"

#define LINE_LEN 80 // max number of chars in path search

#define FPGA_DONE_FILE "/sys/class/xdevcfg/xdevcfg/device/prog_done"
#define FPGA_CFG_FILE "/dev/xdevcfg"

#define PHANTOM_MODULE "uio_pdrv_genirq of_id=phantom_platform,generic-uio,ui_pdrv"

#define AXI_GP0_BASEADDR 0x40000000
#define MAX_AXI_GP0_BASEADDR 0x4f000000
#define AXI_GP1_BASEADDR 0x80000000
#define MAX_AXI_GP1_BASEADDR 0x8f000000
#define AXI_GP_ADDR_RANGE 0x1000000 // set at 16MB for each core (component) mapping

#define DEVCFG_BASE_ADDR 0xf8007000  // Devcfg regs base
#define DEVCFG_CTRL_REG 0x00
#define DEVCFG_LOCK_REG 0x04
#define DEVCFG_CFG_REG 0x08
#define DEVCFG_INT_STS_REG 0x0c
#define DEVCFG_STATUS_REG 0x14
#define DEVCFG_UNLOCK_REG 0x34
#define DEVCFG_MCTRL_REG 0x80
#define PCFG_PROG_B_MASK (1<<30)
#define PCFG_INIT_MASK (1<<4)

#define SLCR_BASE_ADDR 0xf8000000
#define SLCR_FPGA_RST_CTRL_REG 0x240
#define FPGA0_OUT_RST_BM 1U
#define FPGA1_OUT_RST_BM 2U
#define FPGA2_OUT_RST_BM 4U
#define FPGA3_OUT_RST_BM 8U

#define REG_READ_TIMEOUT 1000 // 1000 us timeout

#define PHANTOM_FPGASYS_FILENAME "phantom_fpga.tar.gz"
#define SD_CARD_PHANTOM_DOWNLOAD_LOC SD_CARD_PHANTOM_LOC "download/"
#define SD_CARD_PHANTOM_DOWNLOAD_FILE SD_CARD_PHANTOM_DOWNLOAD_LOC PHANTOM_FPGASYS_FILENAME
#define SD_CARD_PHANTOM_FPGA_LOC SD_CARD_PHANTOM_LOC "fpga"
#define SD_CARD_PHANTOM_FPGA_CONFIG_LOC SD_CARD_PHANTOM_FPGA_LOC "/conf/"
#define SD_CARD_PHANTOM_FPGA_BITFILE_LOC SD_CARD_PHANTOM_FPGA_LOC "/bitfile/"
#define SD_CARD_PHANTOM_FPGA_CONF_FILE SD_CARD_PHANTOM_FPGA_CONFIG_LOC "phantom_fpga_conf.xml"
#define SYSCLASS_LOC "/sys/class/uio/"
#define MAP_ADDR_FILE "/maps/map0/addr"
#define MAP_SIZE_FILE "/maps/map0/size"
#define UIO_NAME "/name"

#define IPCORE_CTRL_ADDR 0x000
#define IPCORE_GIER_ADDR 0x004
#define IPCORE_IER_ADDR 0x008
#define IPCORE_ISR_ADDR 0x00c
#define IPCORE_CTRL_AP_START_BM (1<<0)
#define IPCORE_CTRL_AP_DONE_BM (1<<1)
#define IPCORE_CTRL_AP_IDLE_BM (1<<2)
#define IPCORE_CTRL_AP_READY_BM (1<<3)
#define IPCORE_CTRL_AUTORESTART_BM (1<<7)
#define IPCORE_GIER_EN_BM (1<<0)
#define IPCORE_IER_CH0_BM (1<<0)
#define IPCORE_IER_CH1_BM (1<<1)
#define IPCORE_ISR_CH0_BM (1<<0)
#define IPCORE_ISR_CH1_BM (1<<1)



typedef enum {UIO_DEV_OPENED=1, UIO_DEV_MAPPED=2} uio_dev_flags;


/*
 * public functions prototype
 */
void reg_write(void *reg_base, phantom_address_t, phantom_data_t);
phantom_data_t reg_read(void *, phantom_address_t);
int get_file_str(char*, char*);
int fpga_config_reset();
int fpga_reset(uint8_t);
int map_component(phantom_ip_t *);
int open_devs(void);
void close_devs(void);
void unmap_devs(void);



#endif /* SRC_PHANTOM_API_LOWLEVEL_H_ */
