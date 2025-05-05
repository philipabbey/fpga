//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
//
//-----------------------------------------------------------------------------------
//
// C code for the PS to communicate with the DFX Controller over AXI-Lite.
//
// P A Abbey, 4 May 2025
//
//-----------------------------------------------------------------------------------

#include <xil_io.h>
#include "dfx.h"

// https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/ICAP-Controller
// https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/Register-XDCFG_CTRL_OFFSET-Details
// XDCFG_CTRL_OFFSET @ 0xF8007000
// xsct% mwr 0xF8007000 [expr [mrd -value 0xF8007000] & 0xF7FFFFFF]
// Turn off bit XDCFG_CTRL_PCAP_PR_MASK (PCAP_PR) to enable ICAPE2 to re-program logic
void dfx_enable_icap() {
    Xil_Out32(XDCFG_CTRL_OFFSET, Xil_In32(XDCFG_CTRL_OFFSET) & 0xF7FFFFFF);
}

// The RP needs to be shutdown in order to read the setup values, otherwise they come back 0x0.
void dfx_print_setup() {
    u32 sizes[4];

    Xil_Out32(DFXC_CONTROL, DFXC_SHUTDOWN);
    sizes[0] = Xil_In32(DFXC_BS_SIZE0);
    sizes[1] = Xil_In32(DFXC_BS_SIZE1);
    sizes[2] = Xil_In32(DFXC_BS_SIZE2);
    sizes[3] = Xil_In32(DFXC_BS_SIZE3);

    xil_printf("DFXC_TRIGGER0     = RM %d\n\r",           Xil_In32(DFXC_TRIGGER0));
    xil_printf("DFXC_TRIGGER1     = RM %d\n\r",           Xil_In32(DFXC_TRIGGER1));
    xil_printf("DFXC_TRIGGER2     = RM %d\n\r",           Xil_In32(DFXC_TRIGGER2));
    xil_printf("DFXC_TRIGGER3     = RM %d\n\r",           Xil_In32(DFXC_TRIGGER3));
    xil_printf("DFXC_RM_CONTROL0  = 0x%08X\n\r",          Xil_In32(DFXC_RM_CONTROL0));
    xil_printf("DFXC_RM_CONTROL1  = 0x%08X\n\r",          Xil_In32(DFXC_RM_CONTROL1));
    xil_printf("DFXC_RM_CONTROL2  = 0x%08X\n\r",          Xil_In32(DFXC_RM_CONTROL2));
    xil_printf("DFXC_RM_CONTROL3  = 0x%08X\n\r",          Xil_In32(DFXC_RM_CONTROL3));
    xil_printf("DFXC_BS_ADDRESS0  = 0x%08X\n\r",          Xil_In32(DFXC_BS_ADDRESS0));
    xil_printf("DFXC_BS_SIZE0     = 0x%08X %d bytes\n\r", sizes[0], sizes[0]);
    xil_printf("DFXC_BS_ADDRESS1  = 0x%08X\n\r",          Xil_In32(DFXC_BS_ADDRESS1));
    xil_printf("DFXC_BS_SIZE1     = 0x%08X %d bytes\n\r", sizes[1], sizes[1]);
    xil_printf("DFXC_BS_ADDRESS2  = 0x%08X\n\r",          Xil_In32(DFXC_BS_ADDRESS2));
    xil_printf("DFXC_BS_SIZE2     = 0x%08X %d bytes\n\r", sizes[2], sizes[2]);
    xil_printf("DFXC_BS_ADDRESS3  = 0x%08X\n\r",          Xil_In32(DFXC_BS_ADDRESS3));
    xil_printf("DFXC_BS_SIZE3     = 0x%08X %d bytes\n\r", sizes[3], sizes[3]);
    Xil_Out32(DFXC_CONTROL, DFXC_RESTART_WITH_NO_STATUS);
}

void dfx_print_status() {
    u32 status;
    u8 state;
    u8 error;

    status = Xil_In32(DFXC_STATUS);
    xil_printf("Status = 0x%08X\n\r", status);
    state = status & 0x00000007;
    xil_printf(" State    : %d %s\n\r", state, dfx_state_lu(state));
    error = (status >> 3) & 0x0000000F;
    xil_printf(" Error    : %d\n\r", error, dfx_error_lu(error));
    xil_printf(" Shutdown : %d\n\r", (status >> 7) & 0x00000001);
    xil_printf(" RM_ID    : %d\n\r", (status >> 8) & 0x000000FF);
    xil_printf("SW Trigger = 0x%08X\n\r", Xil_In32(DFXC_SW_TRIGGER));
}

char* dfx_state_lu(u8 state) {
    switch (state) {
        case 0:
            return "Empty";
            break;
        case 1:
            return "HW Shutdown";
            break;
        case 2:
            return "SW Shutdown";
            break;
        case 3:
            return "Clearing BS";
            break;
        case 4:
            return "Loading";
            break;
        case 5:
            return "SW Startup";
            break;
        case 6:
            return "Reset RM";
            break;
        case 7:
            return "Loaded";
            break;
        default:
            return "";
    }
}

char* dfx_error_lu(u8 error) {
    switch (error) {
        case 0:
            return "No Error";
            break;
        case 1:
            // The fetch path was asked to load a 0 byte bitstream
            return "Bad Configuration";
            break;
        case 2:
            // The ICAP returned an error code while loading the bitstream
            return "BS Error";
            break;
        case 3:
            // Access to the ICAPE3 was removed during a bitstream transfer. This error is only possible when the device to be managed is an UltraScale or UltraScale+ device.
            return "Lost Error";
            break;
        case 4:
            // There was an error fetching the bitstream from the configuration library.
            return "Fetch Error";
            break;
        case 5:
            // The ICAP returned an error code while loading the bitstream and there was an error fetching the bitstream from the configuration library.
            return "BS & Fetch errors";
            break;
        case 6:
            // Access to the ICAPE3 was removed during a bitstream transfer, and there was an error fetching the bitstream from the configuration library. This error is only possible when the device to be managed is an UltraScale or UltraScale+ device.
            return "Lost & Fetch errors";
            break;
        case 7:
            // A compressed bitstream ended at an invalid place in the decompression algorithm.
            return "Bad Size Error";
            break;
        case 8:
            // A compressed bitstream was received in the incorrect format.
            return "Bad Format Error";
            break;
        case 15:
            // An unknown error occurred.
            return "Unknown Error";
            break;
        default:
            return "Unassigned error";
    }
}

void dfx_trigger(u8 trigger) {
    Xil_Out32(DFXC_SW_TRIGGER, trigger);
}
