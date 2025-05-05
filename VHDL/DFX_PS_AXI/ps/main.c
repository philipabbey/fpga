//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
//
//-----------------------------------------------------------------------------------
//
// Demonstration bare-metal PS application for the DFX Controller over AXI-Lite.
//
// P A Abbey, 4 May 2025
//
//-----------------------------------------------------------------------------------

#include "sleep.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "dfx.h"

int main() {
    u32 rm = 3;

    xil_printf("Start Running\n\r");
    xil_printf("-------------\n\r");
    dfx_print_setup();
    dfx_enable_icap();
    while (1) {
        usleep(500000); // us
        dfx_print_status();
        // Software requests a sepcific RM to be loaded by the DFX Controller logic over AXI-Lite
        // Counting backwards means its can't be a request from digital logic
        dfx_trigger(rm);
        rm = (rm-1) % 4;
        usleep(500000); // us
        dfx_print_status();
    }
}
