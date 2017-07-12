


/*
 * File:         phantom_xml_parser.h
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


#ifndef SRC_PHANTOM_XML_PARSER_H_
#define SRC_PHANTOM_XML_PARSER_H_


#include "phantom_api.h"
#include <stdio.h>


#define PHANTOM_CONF_VER "0.1"
#define MAXLINELEN 200 // max char length of single XML line
#define MAX_XMLTXT_LEN 64 // max char length of XML element text


/* function protortypes */
uint8_t get_phantom_component_count(void);
phantom_ip_t *get_phantom_component(uint8_t);
int phantom_conf(FILE*);
phantom_platform_info_t *get_phantom_platform_info(void);
phantom_ip_t *get_phantom_component_array(void);


#endif // SRC_PHANTOM_XML_PARSER_H_
