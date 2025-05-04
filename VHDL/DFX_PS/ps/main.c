//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
//
//-----------------------------------------------------------------------------------
//
// C code for the PS to enable the ICAP interface.
//
// P A Abbey, 8 March 2025
//
//-----------------------------------------------------------------------------------

#include "sleep.h"
#include "xil_printf.h"
#include <xil_io.h>
#define XDCFG_CTRL_OFFSET 0xF8007000

int main() {
    xil_printf("Running");
    // https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/ICAP-Controller
    // https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/Register-XDCFG_CTRL_OFFSET-Details
    // XDCFG_CTRL_OFFSET @ 0xF8007000
    // xsct% mwr 0xF8007000 [expr [mrd -value 0xF8007000] & 0xF7FFFFFF]
    // Turn off bit XDCFG_CTRL_PCAP_PR_MASK (PCAP_PR) to enable ICAPE2 to re-program logic
    Xil_Out32(XDCFG_CTRL_OFFSET, Xil_In32(XDCFG_CTRL_OFFSET) & 0xF7FFFFFF);
    
    while (1) {
        sleep(1);
        xil_printf(".");
    }
}
