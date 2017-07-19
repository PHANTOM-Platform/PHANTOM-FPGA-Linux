
#include <stdio.h>
#include <phantom_api.h>
#include <phantom_api_lowlevel.h>


int main() {

    if(phantom_initialise() != PHANTOM_OK) {
        printf("Error during initialise.\n");
        return -1;
    }

    printf("Num IPs: %d\n", phantom_fpga_get_num_ips());
    return 0;
}
