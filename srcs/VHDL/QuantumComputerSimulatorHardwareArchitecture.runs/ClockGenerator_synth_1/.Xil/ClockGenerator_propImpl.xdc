set_property SRC_FILE_INFO {cfile:c:/Users/Jonas/OneDrive/JugendForscht/FPGAQuantumComputerSimulatorAccelerator/HardwareArchitectureQuantumComputerSimulator/QuantumComputerSimulatorHardwareArchitecture.gen/sources_1/ip/ClockGenerator/ClockGenerator.xdc rfile:../../../QuantumComputerSimulatorHardwareArchitecture.gen/sources_1/ip/ClockGenerator/ClockGenerator.xdc id:1 order:EARLY scoped_inst:inst} [current_design]
current_instance inst
set_property src_info {type:SCOPED_XDC file:1 line:54 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports clk_in]] 0.100
