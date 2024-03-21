// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
// Date        : Sun Mar 17 19:40:09 2024
// Host        : Jonas-PC running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/Jonas/OneDrive/JugendForscht/FPGAQuantumComputerSimulatorAccelerator/HardwareArchitectureQuantumComputerSimulator/QuantumComputerSimulatorHardwareArchitecture.gen/sources_1/ip/ClockGenerator/ClockGenerator_stub.v
// Design      : ClockGenerator
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tcpg236-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module ClockGenerator(clk_out_100, clk_out_200, reset, locked, clk_in)
/* synthesis syn_black_box black_box_pad_pin="reset,locked,clk_in" */
/* synthesis syn_force_seq_prim="clk_out_100" */
/* synthesis syn_force_seq_prim="clk_out_200" */;
  output clk_out_100 /* synthesis syn_isclock = 1 */;
  output clk_out_200 /* synthesis syn_isclock = 1 */;
  input reset;
  output locked;
  input clk_in;
endmodule
