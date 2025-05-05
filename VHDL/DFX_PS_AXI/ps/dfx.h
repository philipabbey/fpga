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

#include "xil_printf.h"
#include "xparameters.h"

#define XDCFG_CTRL_OFFSET 0xF8007000

// DFX Controller Address Map
// XPAR_VHDL_CONV_I_BASEADDR + Offset below
// RO
#define DFXC_STATUS       (XPAR_VHDL_CONV_I_BASEADDR + 0X00000)
// WO and is mapped to the same address as the STATUS register
#define DFXC_CONTROL      (XPAR_VHDL_CONV_I_BASEADDR + 0X00000)
// RW
#define DFXC_SW_TRIGGER   (XPAR_VHDL_CONV_I_BASEADDR + 0X00004)
#define DFXC_TRIGGER0     (XPAR_VHDL_CONV_I_BASEADDR + 0X00040)
#define DFXC_TRIGGER1     (XPAR_VHDL_CONV_I_BASEADDR + 0X00044)
#define DFXC_TRIGGER2     (XPAR_VHDL_CONV_I_BASEADDR + 0X00048)
#define DFXC_TRIGGER3     (XPAR_VHDL_CONV_I_BASEADDR + 0X0004C)
    // Can't find which Vivado IP configuration parameter this maps to.
#define DFXC_RM_BS_INDEX0 (XPAR_VHDL_CONV_I_BASEADDR + 0X00080)
#define DFXC_RM_CONTROL0  (XPAR_VHDL_CONV_I_BASEADDR + 0X00084)
    // Can't find which Vivado IP configuration parameter this maps to.
#define DFXC_RM_BS_INDEX1 (XPAR_VHDL_CONV_I_BASEADDR + 0X00088)
#define DFXC_RM_CONTROL1  (XPAR_VHDL_CONV_I_BASEADDR + 0X0008C)
    // Can't find which Vivado IP configuration parameter this maps to.
#define DFXC_RM_BS_INDEX2 (XPAR_VHDL_CONV_I_BASEADDR + 0X00090)
#define DFXC_RM_CONTROL2  (XPAR_VHDL_CONV_I_BASEADDR + 0X00094)
    // Can't find which Vivado IP configuration parameter this maps to.
#define DFXC_RM_BS_INDEX3 (XPAR_VHDL_CONV_I_BASEADDR + 0X00098)
#define DFXC_RM_CONTROL3  (XPAR_VHDL_CONV_I_BASEADDR + 0X0009C)
// UltraScale- only
#define DFXC_BS_ID0       (XPAR_VHDL_CONV_I_BASEADDR + 0X000C0)
#define DFXC_BS_ADDRESS0  (XPAR_VHDL_CONV_I_BASEADDR + 0X000C4)
#define DFXC_BS_SIZE0     (XPAR_VHDL_CONV_I_BASEADDR + 0X000C8)
// UltraScale- only
#define DFXC_BS_ID1       (XPAR_VHDL_CONV_I_BASEADDR + 0X000D0)
#define DFXC_BS_ADDRESS1  (XPAR_VHDL_CONV_I_BASEADDR + 0X000D4)
#define DFXC_BS_SIZE1     (XPAR_VHDL_CONV_I_BASEADDR + 0X000D8)
// UltraScale- only
#define DFXC_BS_ID2       (XPAR_VHDL_CONV_I_BASEADDR + 0X000E0)
#define DFXC_BS_ADDRESS2  (XPAR_VHDL_CONV_I_BASEADDR + 0X000E4)
#define DFXC_BS_SIZE2     (XPAR_VHDL_CONV_I_BASEADDR + 0X000E8)
// UltraScale- only
#define DFXC_BS_ID3       (XPAR_VHDL_CONV_I_BASEADDR + 0X000F0)
#define DFXC_BS_ADDRESS3  (XPAR_VHDL_CONV_I_BASEADDR + 0X000F4)
#define DFXC_BS_SIZE3     (XPAR_VHDL_CONV_I_BASEADDR + 0X000F8)

// Control Register Commands
#define DFXC_SHUTDOWN               0
#define DFXC_RESTART_WITH_NO_STATUS 1
#define DFXC_RESTART_WITH_STATUS    2
#define DFXC_PROCEED                3
#define DFXC_USER_CONTROL           4

void dfx_enable_icap();
void dfx_print_setup();
char* dfx_state_lu(u8 state);
char* dfx_error_lu(u8 error);
void dfx_print_status();
void dfx_trigger(u8 trigger);
