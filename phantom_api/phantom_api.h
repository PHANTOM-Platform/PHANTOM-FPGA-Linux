/*
 * File:         phantom_api.h
 *
 * Project:      PHANTOM
 *
 * Organisation: University of York
 *
 * Author(s):    A. Moulds
 *
 * Version:      0.1 (dev release only)
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



#ifndef SRC_PHANTOM_API_H_
#define SRC_PHANTOM_API_H_


#include <stdint.h>

/* Target Platform definition */
#define PHANTOM_HW_PLATFORM MICROZED
//#define PHANTOM_HW_PLATFORM ZC706
//#define PHANTOM_HW_PLATFORM ZYBO


/* Target SoC FPGA Device definition */
#define FPGA ZYNQ_APSOC
//#define FPGA ZYNQ_MPSOC


/* API Status flags */
#define PHANTOM_OK 0
#define PHANTOM_SUCCESS 0
#define PHANTOM_FALSE -1
#define PHANTOM_ERROR -2
#define PHANTOM_NOT_FOUND -3


/* maximum permitted cores definition */
#define MAX_PHANTOM_COMPONENTS 30


/* register address and data sizes def. */
#if FPGA == ZYNQ_APSOC
   typedef uint32_t phantom_data_t;
   typedef uint32_t phantom_address_t;
#elif FPGA == ZYNQ_MPSOC
   typedef uint64_t phantom_data_t;
   typedef uint64_t  phantom_address_t;
#endif


/* FPGA PS->PL reset signals enumeration. */
typedef enum {FCLKRESETN0=1, FCLKRESETN1=2, FCLKRESETN2=4, FCLKRESETN3=8} fclkresetn_type_t;


/* Struct for representing a single PHANTOM IP core. Can have multiple cores in FPGA PL. */
typedef struct {
    char *ipname; // name of Phantom fpga core
	char *idstring; // assigned fpga core instance name
	uint32_t id; // assigned id number
	uint8_t num_axi_masters;
	phantom_address_t s0_axi_base_address;
	uint32_t s0_axi_address_size;
	phantom_address_t s1_axi_base_address;
	uint32_t s1_axi_address_size;
	uint32_t *s0_vmem_base; /* private */
	uint32_t *s1_vmem_base; /* private */
} phantom_ip_t;


/* Struct to hold PHANTOM platform information. */
typedef struct {
	char *platform;
    char *fpga_type;
    char *fpga_device;
    char *design;
    char *bitfile;
} phantom_platform_info_t;


/* function prototypes */
int phantom_download(int);
int phantom_initialise(void);
int phantom_fpga_is_done();
int phantom_fpga_configure(void);
int phantom_fpga_configuration_reset();
int phantom_fpga_reset(const uint8_t);
int phantom_fpga_reset_global(void);
int phantom_fpga_get_num_ips();
phantom_ip_t *phantom_fpga_get_ips();
phantom_ip_t *phantom_fpga_get_ip(const uint8_t);
phantom_ip_t *phantom_fpga_get_ip_from_idx(const uint8_t);
phantom_ip_t *phantom_fpga_get_ip_from_idstr(const char *);
phantom_ip_t *phantom_fpga_get_ip_from_name(const char *);
int phantom_fpga_ip_start(phantom_ip_t*);
int phantom_fpga_ip_set_autorestart(phantom_ip_t*);
int phantom_fpga_ip_clear_autorestart(phantom_ip_t*);
int phantom_fpga_ip_is_done(phantom_ip_t*);
int phantom_fpga_ip_is_idle(phantom_ip_t*);
int phantom_fpga_ip_set(phantom_ip_t*, const phantom_address_t, const phantom_data_t, const uint8_t);
phantom_data_t phantom_fpga_ip_get(phantom_ip_t*, const phantom_address_t, const uint8_t);
void phantom_terminate(void);
phantom_platform_info_t *phantom_platform_get_info(void);
char *phantom_get_version(void);



#endif // SRC_PHANTOM_API_H_
