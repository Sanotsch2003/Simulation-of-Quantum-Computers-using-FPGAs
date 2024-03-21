-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
-- Date        : Sun Mar 17 19:40:09 2024
-- Host        : Jonas-PC running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               c:/Users/Jonas/OneDrive/JugendForscht/FPGAQuantumComputerSimulatorAccelerator/HardwareArchitectureQuantumComputerSimulator/QuantumComputerSimulatorHardwareArchitecture.gen/sources_1/ip/ClockGenerator/ClockGenerator_stub.vhdl
-- Design      : ClockGenerator
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a35tcpg236-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ClockGenerator is
  Port ( 
    clk_out_100 : out STD_LOGIC;
    clk_out_200 : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC;
    clk_in : in STD_LOGIC
  );

end ClockGenerator;

architecture stub of ClockGenerator is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_out_100,clk_out_200,reset,locked,clk_in";
begin
end;
