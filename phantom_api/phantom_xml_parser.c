/*
 * File:         phantom_xml_parser.c
 *
 * Project:      PHANTOM
 *
 * Organisation: University of York
 *
 * Author(s):    A. Moulds
 *
 * Version:      0.11 (dev release only)
 *
 * Description:
 *
 * Copyright:    University of York. 2017.
 *
 * Legal:        All rights reserved. No warranty, explicit or implicit, provided.
 *
 * Revisions:
 *
 * 		0.11	Changes
 * 				1. Corrected behaviour of get_linestr().
 * 				2. fixed bug in get_phantom_component().
 *
 *
*/



#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "phantom_xml_parser.h"


/* static globals */
static phantom_ip_t ph_comp[MAX_PHANTOM_COMPONENTS+1];
static char ph_comp_name[MAX_PHANTOM_COMPONENTS][MAX_XMLTXT_LEN];
static char ph_comp_idstring[MAX_PHANTOM_COMPONENTS][MAX_XMLTXT_LEN];
static phantom_platform_info_t ph_platform_info;
static char ph_fpga_type[MAX_XMLTXT_LEN];
static char ph_fpga_device[MAX_XMLTXT_LEN];
static char ph_fpga_board[MAX_XMLTXT_LEN];
static char ph_design_name[MAX_XMLTXT_LEN];
static char ph_design_bitfile[MAX_XMLTXT_LEN];
uint8_t no_of_ph_comps = 0;
    

/* private functions prototype */
static ssize_t get_linestr(FILE*, char*);
static int get_datastr(char*, char*);
static int is_xml_header(char*, const char*, int, char*);
static int find_xml_header(FILE*, const char*, int, char*);
static int check_for_version(FILE*, const char*);
static int is_xml_tag(const char*, const char*, int);
static char *get_element_text(char*);
static int get_phantom_comp(FILE*, phantom_ip_t*);



static ssize_t get_linestr(FILE *fp, char *str)
{
    char *line=NULL;
    size_t len = 0;
    ssize_t nread;  
  
    memset(str,'\0', MAXLINELEN);
    nread = getline(&line, &len, fp);
    if(nread == -1)
        return -1;
    strncpy(str, line, nread);
    free(line); 
    return nread;
}



static int get_datastr(char* sptr, char* datastr)
{        
    char *pf,*pb;
    int len;
  
    pf=strchr(sptr, '\"');
    pb=strchr(pf+1, '\"');
    len = pb - pf - 1;
    if (len < 1)
        return -1;
    memcpy(datastr, pf + 1, len);
    return 0;
    
}



static int is_xml_header(char *str, const char *header, int len, char* datastr)
{
    char *sptr;
    
    if((sptr = strstr(str, "<?")) == NULL)
        return -1;
    if((sptr = strstr(sptr, header)) == NULL)
        return -1;
    if(get_datastr(sptr, datastr))
        return -1;
    if((sptr = strstr(str, "?>")) == NULL)
        return -1;

    return 0;
}



static int find_xml_header(FILE* fp,const char *header, int len, char* datastr)
{
    char str[MAXLINELEN];    
    
    while(get_linestr(fp, str) != -1)
    {
        if(is_xml_header(str,header,len, datastr)==0)
            return 0;
    }
    return -1;
}



static int check_for_version(FILE* fp, const char* ver)
{
    char data_str[MAXLINELEN];
        
    fseek(fp,0,SEEK_SET);
        
    if (find_xml_header(fp, "phantom conf file version", strlen("phantom conf file version"), data_str))
    {
        return -1;           
    }
    if (strncmp(data_str, ver, 3)) // note: just check first three chars in ver
    {
        return -1;            
    }
    
    return 0;
}



static int is_xml_tag(const char *str,const char* tag, int len)
{
    char tmp[MAXLINELEN]; 
    char *sptr;
 
    if((sptr = strchr(str,'<'))==NULL)
        return -1;
        sptr += 1;
    if ((*sptr == '!')||(*sptr == '?')||(*sptr==' '))
        return -1;
    strcpy(tmp,tag);
    strcat(tmp, ">"); 
    return strncmp(sptr, tmp, len+1);
}



static char *get_element_text(char* line)
{
    char tmp[MAXLINELEN]; 
    char *sptr1, *sptr2;
    
    strcpy(tmp, line);  
    memset(line, '\0', MAXLINELEN);
 
    if((sptr1 = strchr(tmp, '>'))==NULL)
        return '\0';
        
    sptr1++;
    if((sptr2 = strchr(sptr1, '<'))==NULL)
        return '\0';  
    
   return strncpy(line,sptr1, sptr2-sptr1);
        
}
         
            

static int get_phantom_comp(FILE *fp, phantom_ip_t *ph_ip_ptr)
{
    char str[MAXLINELEN];      
    long fp_start, fp_end;
    int tag_found = 0;
    int lineno = 0, i;
    
     fp_start = ftell(fp);
     while(get_linestr(fp, str) != -1)
    {
        if(!is_xml_tag(str,"/component_inst",strlen("/component_inst")))
        {
            tag_found = 1;
            break;
        } 
        lineno += 1;
    }  
    if(!tag_found)
        return -1;

    fp_end = ftell(fp);


    fseek(fp, fp_start,SEEK_SET);
    for(i=0; i < lineno; i++)
    {
        get_linestr(fp, str);
        if(!is_xml_tag(str,"name",strlen("name")))
        {
            memcpy(ph_ip_ptr->idstring, get_element_text(str),MAX_XMLTXT_LEN);
            break;
        }
    }

    fseek(fp, fp_start,SEEK_SET);
    for(i=0; i < lineno; i++)
    {
        
        get_linestr(fp, str);
        if(!is_xml_tag(str,"ipname",strlen("ipname")))
        {
           memcpy(ph_ip_ptr->ipname, get_element_text(str),MAX_XMLTXT_LEN);
            break;
        }
         
    } 
    
    fseek(fp, fp_start,SEEK_SET);
    for(i=0; i < lineno; i++)
    {
        get_linestr(fp, str);
        if(!is_xml_tag(str,"id",strlen("id")))
        {
            ph_ip_ptr->id = (uint32_t) strtoul(get_element_text(str), NULL, 0);
            break;
        }
    }  

    fseek(fp, fp_start,SEEK_SET);
    for(i=0; i < lineno; i++)
    {
        get_linestr(fp, str);
        if(!is_xml_tag(str,"slave_addr_base_0",strlen("slave_addr_base_0")))
        {
            ph_ip_ptr->s0_axi_base_address = (phantom_address_t) strtoul(get_element_text(str), NULL, 0);
            break;
        }
    } 

    fseek(fp, fp_start,SEEK_SET);
    for(i=0; i < lineno; i++)
    {
        get_linestr(fp, str);
        if(!is_xml_tag(str,"slave_addr_base_1",strlen("slave_addr_base_1")))
        {
            ph_ip_ptr->s1_axi_base_address = (phantom_address_t) strtoul(get_element_text(str), NULL, 0);
            break;
        }
    } 
    
    fseek(fp, fp_start,SEEK_SET);
    for(i=0; i < lineno; i++)
    {
        get_linestr(fp, str);
        if(!is_xml_tag(str,"slave_addr_range_0",strlen("slave_addr_range_0")))
        {
            ph_ip_ptr->s0_axi_address_size = (uint32_t) strtoul(get_element_text(str), NULL, 0);
            break;
        }
    } 

    fseek(fp, fp_start,SEEK_SET);
    for(i=0; i < lineno; i++)
    {
        get_linestr(fp, str);
        if(!is_xml_tag(str,"slave_addr_range_1",strlen("slave_addr_range_1")))
        {
            ph_ip_ptr->s1_axi_address_size = (uint32_t) strtoul(get_element_text(str), NULL, 0);
            break;
        }
    } 

    fseek(fp, fp_start,SEEK_SET);
    for(i=0; i < lineno; i++)
    {
        get_linestr(fp, str);
        if(!is_xml_tag(str,"num_masters",strlen("num_masters")))
        {
            ph_ip_ptr->num_axi_masters = (uint8_t) strtoul(get_element_text(str), NULL, 0);
            break;
        }
    }
   
    fseek(fp, fp_end, SEEK_SET);
    return 0;    
}



////////////////////////////////////////////////////////////////////
/*
 * Function to extract info from supplied XML file.
 * Parameters:
 *    fp: File pointer to opened XML file.
 *    ph_comp_idx : pointer to integer to contain returned component count.
 * Return:
 *    Zero on success.
 */ 
int phantom_conf(FILE *fp)
{
    char str[MAXLINELEN];  
    int tag_found = 0;
    fpos_t block_start;
    int i, linecnt = 0;
    int ph_comp_idx;

    extern phantom_ip_t ph_comp[MAX_PHANTOM_COMPONENTS+1];
    extern char ph_comp_name[MAX_PHANTOM_COMPONENTS][MAX_XMLTXT_LEN];
    extern char ph_comp_idstring[MAX_PHANTOM_COMPONENTS][MAX_XMLTXT_LEN];
    extern phantom_platform_info_t ph_platform_info;
    extern char ph_fpga_type[MAX_XMLTXT_LEN];
    extern char ph_fpga_device[MAX_XMLTXT_LEN];
    extern char ph_fpga_board[MAX_XMLTXT_LEN];
    extern char ph_design_name[MAX_XMLTXT_LEN];
    extern char ph_design_bitfile[MAX_XMLTXT_LEN];
    extern uint8_t no_of_ph_comps;
    
    //
    // check opened xml file version is valid
    if(check_for_version(fp, PHANTOM_CONF_VER))
    {
		#ifdef DEBUG
    		printf("error: incompatible xml format\n");
    	#endif
        return -1;
    }

    //
    // initialise static memory for ph_platform_info struct.
    memset(ph_fpga_type, '\0', MAX_XMLTXT_LEN);
    memset(ph_fpga_device, '\0', MAX_XMLTXT_LEN);
    memset(ph_fpga_board, '\0', MAX_XMLTXT_LEN);
    memset(ph_design_name, '\0', MAX_XMLTXT_LEN);
    memset(ph_design_bitfile, '\0', MAX_XMLTXT_LEN);
    ph_platform_info.platform = ph_fpga_board;
    ph_platform_info.fpga_type = ph_fpga_type;
    ph_platform_info.fpga_device = ph_fpga_device;
    ph_platform_info.design = ph_design_name;
    ph_platform_info.bitfile = ph_design_bitfile;
        
    //
    // create and initialise static memory for phantom components 
    for(i = 0; i < MAX_PHANTOM_COMPONENTS; i++)
    {
        memset(ph_comp_idstring[i], '\0', MAX_XMLTXT_LEN);
        memset(ph_comp_name[i], '\0', MAX_XMLTXT_LEN);
        ph_comp[i].idstring = (char *) &ph_comp_idstring[i];
        ph_comp[i].ipname = (char *) &ph_comp_name[i];
        ph_comp[i].id = 0;
        ph_comp[i].num_axi_masters = 0;
        ph_comp[i].s0_axi_address_size = 0;
        ph_comp[i].s0_axi_base_address = 0;
        ph_comp[i].s1_axi_address_size = 0;
        ph_comp[i].s1_axi_base_address = 0;
        ph_comp[i].s0_vmem_base = NULL;
        ph_comp[i].s1_vmem_base = NULL;
    }

    //
    // determine range of lines in xmlfile for parent tag 'phantom_fpga'
    fseek(fp, 0, SEEK_SET);
    while(get_linestr(fp, str) != -1)
    {
        //find parent 'phantom_fpga' tag
        if(!is_xml_tag(str, "phantom_fpga", strlen("phantom_fpga")))
        {
            tag_found = 1;
            fgetpos(fp, &block_start);
            break;
        }
    }
    if(!tag_found)
    {
		#ifdef DEBUG
			printf("error in xml file - unable to find phantom_fpga tag.\n");
		#endif
    	return -1;
    }

    tag_found = 0;
    while(get_linestr(fp, str) != -1)
    {
        if(!is_xml_tag(str,"/phantom_fpga",strlen("/phantom_fpga")))
        {
            tag_found = 1;
            break;
        }
        linecnt += 1;
    }
    if(!tag_found)
    {
		#ifdef DEBUG
			printf("error in xml file - unable to find /phantom_fpga tag.\n");
		#endif
    	return -1;
    }
       
    //
    // copy xml for platform fpga and design details.
    fsetpos(fp,&block_start);
    for(i=0; i < linecnt; i++)
    {
        get_linestr(fp, str);
        if(!is_xml_tag(str,"fpga_type", strlen("fpga_type")))
        {
           memcpy(ph_platform_info.fpga_type, get_element_text(str),MAX_XMLTXT_LEN);
            break;
        }
    }
    fsetpos(fp,&block_start);
    for(i=0; i < linecnt; i++)
    {
        get_linestr(fp, str);
        if(!is_xml_tag(str,"target_device", strlen("target_device")))
        {
           memcpy(ph_platform_info.fpga_device, get_element_text(str),MAX_XMLTXT_LEN);
            break;
        }
    }    
    fsetpos(fp,&block_start);
    for(i=0; i < linecnt; i++)
    {
        get_linestr(fp, str);
        if(!is_xml_tag(str,"target_board", strlen("target_board")))
        {
           memcpy(ph_platform_info.platform, get_element_text(str),MAX_XMLTXT_LEN);
            break;
        }
    }
    fsetpos(fp,&block_start);
    for(i=0; i < linecnt; i++)
    {
        get_linestr(fp, str);
        if(!is_xml_tag(str,"design_name", strlen("design_name")))
        {
           memcpy(ph_platform_info.design, get_element_text(str),MAX_XMLTXT_LEN);
            break;
        }
    }
    fsetpos(fp,&block_start);
    for(i=0; i < linecnt; i++)
    {
        get_linestr(fp, str);
        if(!is_xml_tag(str,"design_bitfile", strlen("design_bitfile")))
        {
           memcpy(ph_platform_info.bitfile, get_element_text(str),MAX_XMLTXT_LEN);
            break;
        }
    }
    
    //
    // now copy phantom component specs and fill structs
    fsetpos(fp,&block_start);
    ph_comp_idx = 0;
    for(i=0; i < linecnt; i++)
    {
        get_linestr(fp, str);
        if(!is_xml_tag(str,"component_inst",strlen("component_inst")))
        {
            if(get_phantom_comp(fp, &ph_comp[ph_comp_idx]))
            {
        		#ifdef DEBUG
        			printf("error in xlm component_int group.\n");
        		#endif
            	return -1;
            }
            ph_comp_idx += 1;
            if(ph_comp_idx > MAX_PHANTOM_COMPONENTS)
            {
        		#ifdef DEBUG
        			printf("error: too many components found in xml file.\n");
        		#endif
            	return -1;
            }
        }
    }

    no_of_ph_comps = ph_comp_idx;
    return 0;
}


////////////////////////////////////////////////////////////////////
/*
 * Function to return number of phantom component specified in xml file.
 * Parameters:
 *    None.
 * Return:
 *    number of phantom components
*/
uint8_t inline get_phantom_component_count(void)
{
	extern uint8_t no_of_ph_comps;
    return no_of_ph_comps;
}


////////////////////////////////////////////////////////////////////
/*
 * Function to return phantom component, referenced from index obtained
 * during call to phantom_conf(). Note: 0 is first index value.
 * Parameters:
 *    idx.
 * Return:
 *    struct detailing phantom component
*/ 
phantom_ip_t inline *get_phantom_component(uint8_t idx)
{
    if(idx < 0)
       return NULL;
    return  &ph_comp[idx];
}



////////////////////////////////////////////////////////////////////
/*
 * Function to return phantom fpga platform information, loaded from conf xml. 
 * Parameters:
 *    None.
 * Return:
 *    struct detailing phantom target h/w
*/ 
phantom_platform_info_t inline *get_phantom_platform_info(void)
{
    return &ph_platform_info;
}



////////////////////////////////////////////////////////////////////
phantom_ip_t inline *get_phantom_component_array(void)
{
    return ph_comp;
}


