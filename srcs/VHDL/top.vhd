library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity top is
generic(
    nCores: integer:=2; --changable
    precision: integer:=64; --not changable without breaking code
    maxQubits: integer:=14; --not changable without breaking code
    baudRate : integer:=460800; --921600 --changable
    clockFrequency : integer:=100000000; --changable this is used for timing purposes. no need to be changed as the timer can run at a different frequency than the processing
    instruction_address_width : integer:=10; --not changable without breaking code
    instruction_width : integer := 8 --not changable without breaking code
);
port(
    clk: in std_logic; --clock
    reset_btn: in std_logic; --reset the current program
    tx: out std_logic; --data out
    rx: in std_logic; --data in
    seg: out std_logic_vector(6 downto 0); --seven segment leds
    an: out std_logic_vector(3 downto 0); --seven segment digits
    led : out std_logic_vector(15 downto 0);--overflow leds
    clk_reset: in std_logic
    );
    
end top;

architecture Behavioral of top is
    
    --declare components
    
    component clockGenerator
        port
         (-- Clock in ports
          -- Clock out ports
          clk_100          : out    std_logic;
          clk_200          : out    std_logic;
          clk_250          : out    std_logic;
          -- Status and control signals
          reset             : in     std_logic;
          locked            : out    std_logic;
          clk_in           : in     std_logic
         );
        end component;
    
    component controlUnit is  
        generic(
            maxQubits : integer;
            precision : integer;
            nCores : integer);   
        Port (
            clk : in std_logic;
            clk_rdy : in std_logic;
            reset : in std_logic;
            
            --instruction signals
            instruction : in unsigned(7 downto 0);
            program_counter_out : out unsigned(9 downto 0);
            
            --processing
            target_qubit_out : out unsigned(3 downto 0);       
            control_qubit_out : out unsigned(3 downto 0);
            apply_control_gate_out : out std_logic;
            target_matrix : out std_logic_vector(11 downto 0);
            cores_reset : out std_logic := '0';

            --ram controller
            ram_controller_en : out std_logic := '0';
            nQubits_out : out unsigned(3 downto 0) := (others => '0');
            ram_controller_busy : in std_logic;
            ram_controller_reset : out std_logic;
            
            --RAM
            ram_write_enable : out std_logic := '0';
            ram_read_enable : out std_logic := '0';
            ram_address_read : out unsigned(maxQubits-1 downto 0);
            ram_address_write : out unsigned(maxQubits-1 downto 0);
            ram_data_in : out std_logic_vector(precision-1 downto 0);
           
            --uart
            uartTransmit_busy : in std_logic;
            uartTransmit_reset : out std_logic;
            uartTransmit_start : out std_logic;
            
            --timer
            timer_reset : out std_logic;
            timer_count_enable : out std_logic
    
            
        
        );
    end component;
    
    component programMemory is
        port (
            clk : in std_logic; 
            address_read : in unsigned(9 downto 0); 
            data_out : out unsigned(7 downto 0);
            data_in: in unsigned(7 downto 0);
            write_enable : in std_logic
            );
     end component;
         
    component RAM is
        generic(
            maxQubits : integer;
            precision : integer 
            );
    
        port (
            clk : in std_logic; -- Clock input
            write_enable : in std_logic; -- Bus write enable signal
            address_write : in unsigned(maxQubits-1 downto 0); 
            address_read : in unsigned(maxQubits-1 downto 0); 
            read_enable : in std_logic; -- Bus read enable signal
            data_in : in std_logic_vector(precision-1 downto 0);
            data_out : out std_logic_vector(precision-1 downto 0)
            );
      end component;
    
    component uartTransmitter is
        generic(
                precision: integer;
                clockFrequency: integer;
                baudRate: integer
                ); 
        Port (
              clk : in std_logic; --clock
              tx_start : in std_logic;
              tx : out std_logic;
              tx_busy : out std_logic;
              reset : in std_logic;
              data : in std_logic_vector(precision-1 downto 0));
     end component;
     
     component timer is
        Port ( 
            clk : in std_logic;
            count_enable : in std_logic;
            reset : in std_logic;
            seg: out std_logic_vector(6 downto 0);
            an: out std_logic_vector(3 downto 0);
            overflow: out std_logic_vector(15 downto 0)
            );
      end component;
      
     component uartReceiver is
          Generic(
                instruction_width: integer;
                baud_rate : integer;
                clk_frequency : integer;
                instruction_address_width : integer
                );
          Port (
                clk: in std_logic;
                rx: in std_logic;
                program_memory_write_enable: out std_logic;
                program_memory_data_in : out unsigned(instruction_width-1 downto 0);
                program_memory_address : out unsigned(instruction_address_width-1 downto 0);
                reset: out std_logic);
     end component;
    
    component RAMController is
          Generic(
                  nCores : integer:= 1;
                  precision : integer:=64;
                  maxQubits : integer:=14
                );
          Port (
                clk : in std_logic;
                reset : in std_logic;
                enable : in std_logic;
                busy : out std_logic := '0';
                
                nQubits_in : in unsigned(3 downto 0);
                
                cores_input_statuses  : std_logic_vector(2*nCores-1 downto 0);
                cores_output_statuses : std_logic_vector(2*nCores-1 downto 0);
                cores_set_input_statuses : out std_logic_vector(nCores-1 downto 0);
                cores_set_output_statuses : out std_logic_vector(nCores-1 downto 0);
                
                RAM_write_enable : out std_logic;
                RAM_read_enable : out std_logic;
                
                core_write_addresses_to_temp_cache_en : out std_logic_vector(nCores-1 downto 0);
                core_cacheUpdateAandB_enables : out std_logic_vector(ncores-1 downto 0);
                core_enables : out std_logic_vector(nCores - 1 downto 0) := (others => '0');
                core_cache_read_addresses_en : out std_logic_vector(4*nCores-1 downto 0);
                core_cache_write_data_en : out std_logic_vector(2*nCores-1 downto 0);
                core_cache_read_data_en : out std_logic_vector(2*nCores-1 downto 0);
                core_indices_out : out std_logic_vector(maxQubits*nCores-1 downto 0);
                cores_ready : in std_logic_vector(nCores-1 downto 0)
                );
     end component;
     
     
    component processingComponent is
    Generic(
            precision: integer:=64; 
            maxQubits: integer:=14
    );
    
    Port (
          clk: in std_logic;
          reset: in std_logic;
          enable: in std_logic;
          index: in unsigned(maxQubits-1 downto 0);
          target_qubit: in unsigned(3 downto 0);
          control_qubit: in unsigned(3 downto 0);
          control_enable : in std_logic;
          target_matrix: in std_logic_vector(11 downto 0);
         
          cacheUpdateAandB_en : in std_logic;
          write_addresses_to_temp_cache_en : in std_logic;
          
          input_cache_address : out std_logic_vector(maxQubits-1 downto 0);
          output_cache_address : out std_logic_vector(maxQubits-1 downto 0);
          
          cache_read_addreses_en : in std_logic_vector(3 downto 0);
          
          cache_data_in : in std_logic_vector(precision-1 downto 0);
          cache_data_out : out std_logic_vector(precision-1 downto 0) := (others => '0');
          
          cache_write_data_en : in std_logic_vector(1 downto 0);
          cache_read_data_en : in std_logic_vector(1 downto 0);

          input_status_out : out std_logic_vector(1 downto 0) := (others => '0');
          set_input_status_external : in std_logic;
          
          output_status_out : out std_logic_vector(1 downto 0) := (others => '0');
          set_output_status_external : in std_logic;
          
          ready : out std_logic
          
     
    );
    end component;
    
     --internal signals
     -- clocks
     signal w_clk_100 : std_logic;
     signal w_clk_200 : std_logic;
     signal w_clk_250 : std_logic;
     signal w_clk_rdy : std_logic;
     
     --resets
     signal w_main_reset : std_logic;
     
     --bus
     signal w_ram_data_in : std_logic_vector(precision-1 downto 0);
     
     --control Unit
     signal w_program_counter : unsigned(9 downto 0);
     signal w_instruction : unsigned(7 downto 0);
     signal w_control_unit_ram_address_read: unsigned(maxQubits-1 downto 0);
     signal w_control_unit_ram_address_write: unsigned(maxQubits-1 downto 0);
     signal w_control_unit_ram_data_in : std_logic_vector(precision-1 downto 0);
     signal w_control_unit_timer_reset: std_logic := '0';
     signal w_control_unit_ram_read_en : std_logic;
     signal w_control_unit_ram_write_en : std_logic;
     
     signal w_target_qubit : unsigned(3 downto 0);
     signal w_control_qubit : unsigned(3 downto 0);
     signal w_apply_as_control_en : std_logic;      
     signal w_matrix : std_logic_vector(11 downto 0);
     signal w_control_unit_ram_controller_reset : std_logic;
    
     -- RAM
     signal w_ram_address_read : unsigned(maxQubits-1 downto 0);
     signal w_ram_address_write : unsigned(maxQubits-1 downto 0);
     signal w_ram_read_en : std_logic := '0';
     signal w_ram_write_en : std_logic := '0';
     signal w_ram_data_out : std_logic_vector(precision-1 downto 0);
     
     --uart out
     signal w_tx_busy : std_logic:= '0';
     signal w_tx_start : std_logic:= '0';
     signal w_tx_reset : std_logic:= '0';
       
    --timer
    signal w_timer_reset : std_logic := '0';
    signal w_timer_count_enable : std_logic := '0';
    
    --program memory
    signal w_program_memory_data_in: unsigned(7 downto 0);
    signal w_program_memory_write_enable : std_logic;
    signal w_program_memory_address : unsigned(instruction_address_width-1 downto 0);
    
    --uartReceiver
    signal w_uartReceiver_reset_out : std_logic;
    signal w_uartReceiver_program_memory_address_out : unsigned(instruction_address_width-1 downto 0);
    
    --RAM Controller
    signal w_ram_controller_reset : std_logic;
    signal w_ram_controller_en : std_logic;
    signal w_ram_controller_ram_write_en : std_logic;
    signal w_ram_controller_ram_read_en : std_logic;
    signal w_ram_controller_busy : std_logic;
    
    signal w_ram_controller_core_cache_read_data_en : std_logic_vector(2*nCores-1 downto 0);
    signal w_ram_controller_core_cache_write_data_en : std_logic_vector(2*nCores-1 downto 0);
    
    signal w_nQubits : unsigned(3 downto 0);
    
    
    --processing Cores
    signal w_cores_reset : std_logic;
    signal w_cores_enable : std_logic_vector(nCores -1 downto 0);
    signal w_cores_indices : std_logic_vector(nCores*maxQubits-1 downto 0);
    signal w_cores_read_addresses_en : std_logic_vector(4*nCores-1 downto 0);
    signal w_cores_input_cache_addresses : std_logic_vector(nCores*maxQubits-1 downto 0);
    signal w_cores_output_cache_addresses : std_logic_vector(nCores*maxQubits-1 downto 0);
    signal w_cores_data_out : std_logic_vector(nCores*precision-1 downto 0);
    signal w_cores_ready : std_logic_vector(nCores-1 downto 0);
    
    signal w_cores_input_statuses  : std_logic_vector(2*nCores-1 downto 0);
    signal w_cores_output_statuses : std_logic_vector(2*nCores-1 downto 0);
    signal w_cores_set_input_statuses : std_logic_vector(nCores-1 downto 0);
    signal w_cores_set_output_statuses : std_logic_vector(nCores-1 downto 0);
    
    signal w_cores_cacheUpdateAandB_en : std_logic_vector(nCores-1 downto 0);
    signal w_cores_write_addresses_to_temp_cache_en : std_logic_vector(nCores-1 downto 0);


begin

    clk_generator : clockGenerator
       port map ( 
                 -- Clock out ports  
                  clk_100 => w_clk_100,
                  clk_200 => w_clk_200,
                  clk_250 => w_clk_250,
                 -- Status and control signals                
                  reset => clk_reset,
                  locked => w_clk_rdy,
                  -- Clock in ports
                  clk_in => clk);
                  

    controlUnit_inst : controlUnit
        generic map(
                    maxQubits => maxQubits,
                    precision => precision,
                    nCores => nCores)
        port map(
                 clk => w_clk_100,
                 clk_rdy => w_clk_rdy,
                 reset => w_main_reset,
                 --instruction signals
                 instruction => w_instruction,
                 program_counter_out => w_program_counter,
                 
                 --processing
                 control_qubit_out => w_control_qubit,
                 target_qubit_out => w_target_qubit,
                 apply_control_gate_out => w_apply_as_control_en,
                 cores_reset => w_cores_reset,
                 
                 --ram controller
                 
                 ram_controller_en => w_ram_controller_en,
                 ram_controller_busy => w_ram_controller_busy,
                 nQubits_out => w_nQubits,
                 ram_controller_reset => w_control_unit_ram_controller_reset,
                 
                 --state memory
                 ram_write_enable => w_control_unit_ram_write_en,
                 ram_read_enable => w_control_unit_ram_read_en,
                 ram_address_read => w_control_unit_ram_address_read,
                 ram_address_write => w_control_unit_ram_address_write,
                 ram_data_in => w_control_unit_ram_data_in,
                 
                 target_matrix => w_matrix,
                 
                 --uart
                 uartTransmit_busy => w_tx_busy,
                 uartTransmit_reset => w_tx_reset,
                 uartTransmit_start => w_tx_start,
                
                 --timer
                 timer_reset => w_control_unit_timer_reset,
                 timer_count_enable => w_timer_count_enable
                );
                 
    programMemory_inst : programMemory
        port map(
                 clk => w_clk_100,
                 address_read => w_program_memory_address,
                 data_out => w_instruction,
                 data_in => w_program_memory_data_in,
                 write_enable => w_program_memory_write_enable);
                             
    RAM_inst : RAM
        generic map(
                    maxQubits => maxQubits,
                    precision => precision)
        port map(
                 clk => w_clk_200,
                 write_enable => w_ram_write_en,
                 address_write => w_ram_address_write,
                 address_read => w_ram_address_read,
                 data_in => w_ram_data_in,
                 data_out => w_ram_data_out,
                 read_enable => w_ram_read_en);
                
    uartTransmitter_inst : uartTransmitter
        generic map(
                    precision => precision,
                    clockFrequency => clockFrequency,
                    baudRate => baudRate)
        port map(
              clk => w_clk_100,
              tx_start => w_tx_start,
              tx => tx, 
              tx_busy => w_tx_busy,
              reset => w_tx_reset,
              data => w_ram_data_out);
              
    timer_inst : timer
        port map(clk => w_clk_100,
                 count_enable => w_timer_count_enable,
                 reset => w_timer_reset,
                 seg => seg,
                 an => an,
                 overflow => led
                );
                
    uartReceiver_inst: uartReceiver 
          generic map(
                instruction_width => instruction_width,
                baud_rate => baudRate,
                clk_frequency => clockFrequency,
                instruction_address_width => instruction_address_width
                )
          port map(
                clk => w_clk_100,
                rx => rx,
                program_memory_write_enable => w_program_memory_write_enable,
                program_memory_data_in => w_program_memory_data_in,
                program_memory_address => w_uartReceiver_program_memory_address_out,
                reset => w_uartReceiver_reset_out);
    
    --generate Cores
    generate_cores: for i in 0 to nCores-1 generate
        core: processingComponent
            generic map(
                    maxQubits => maxQubits,
                    precision => precision
                    )              
            port map(
                    clk => w_clk_200,
                    reset => w_cores_reset,
                    enable => w_cores_enable(nCores-i-1),
                    index => unsigned(w_cores_indices(maxQubits*(nCores-i)-1 downto maxQubits*(nCores-i-1))),
                    target_qubit => w_target_qubit,
                    control_qubit => w_control_qubit,
                    control_enable => w_apply_as_control_en,
                    target_matrix => w_matrix,
                    
                    input_cache_address => w_cores_input_cache_addresses(maxQubits*(nCores-i)-1 downto maxQubits*(nCores-i-1)),
                    output_cache_address => w_cores_output_cache_addresses(maxQubits*(nCores-i)-1 downto maxQubits*(nCores-i-1)),
                    cache_read_addreses_en => w_cores_read_addresses_en(4*(nCores-i)-1 downto 4*(nCores-i-1)),
                      
                    cache_data_in => w_ram_data_out,
                    cache_data_out => w_cores_data_out(precision*(nCores-i)-1 downto precision*(nCores-i-1)),
                      
                    cache_write_data_en => w_ram_controller_core_cache_write_data_en(2*(nCores-i)-1 downto 2*(nCores-i-1)),
                    cache_read_data_en => w_ram_controller_core_cache_read_data_en(2*(nCores-i)-1 downto 2*(nCores-i-1)),
                      
                    input_status_out => w_cores_input_statuses(2*(nCores-i)-1 downto 2*(nCores-i-1)),
                    output_status_out => w_cores_output_statuses(2*(nCores-i)-1 downto 2*(nCores-i-1)),
                    set_input_status_external => w_cores_set_input_statuses(nCores-i-1),
                    set_output_status_external => w_cores_set_output_statuses(nCores-i-1),
                    
                    cacheUpdateAandB_en => w_cores_cacheUpdateAandB_en(nCores-i-1),
                    write_addresses_to_temp_cache_en => w_cores_write_addresses_to_temp_cache_en(nCores-i-1),
                    
                    ready => w_cores_ready(nCores-i-1)
                    );
    end generate;
            
    RAM_controller_inst : RAMController
        generic map(
                    nCores => nCores,
                    precision => precision,
                    maxQubits => maxQubits
                    )
                    
        port map(
                  clk => w_clk_200,
                  reset => w_ram_controller_reset,
                  enable => w_ram_controller_en,
                  busy => w_ram_controller_busy,

                  nQubits_in => w_nQubits,
                    
                  cores_input_statuses => w_cores_input_statuses,
                  cores_output_statuses => w_cores_output_statuses,
                  cores_set_input_statuses => w_cores_set_input_statuses,
                  cores_set_output_statuses => w_cores_set_output_statuses,
                    
                  RAM_write_enable => w_ram_controller_ram_write_en,
                  RAM_read_enable => w_ram_controller_ram_read_en,
                  
                  core_write_addresses_to_temp_cache_en => w_cores_write_addresses_to_temp_cache_en,
                  core_cacheUpdateAandB_enables => w_cores_cacheUpdateAandB_en,
                  core_enables => w_cores_enable,
                  core_cache_read_addresses_en => w_cores_read_addresses_en,
                  core_cache_read_data_en => w_ram_controller_core_cache_read_data_en,
                  core_cache_write_data_en => w_ram_controller_core_cache_write_data_en,
                  core_indices_out => w_cores_indices,
                  cores_ready => w_cores_ready
                 );
      
              
    
    process(w_cores_input_cache_addresses, w_control_unit_ram_address_read) 
    variable result : unsigned(maxQubits-1 downto 0);
    begin
        result := (others => '0');
        if to_integer(w_control_unit_ram_address_read) /= 0 then
            result := w_control_unit_ram_address_read;
        else
            for i in 0 to nCores-1 loop
                if to_integer(unsigned(w_cores_input_cache_addresses(maxQubits*(nCores-i)-1 downto maxQubits*(nCores-i-1)))) /= 0 then
                    result := unsigned(w_cores_input_cache_addresses(maxQubits*(nCores-i)-1 downto maxQubits*(nCores-i-1)));
                end if;
            
            end loop;
            
        end if;
        w_ram_address_read <= result;
    end process;
    
    process(w_cores_output_cache_addresses, w_control_unit_ram_address_write) 
    variable result : unsigned(maxQubits-1 downto 0);
    begin
        result := w_control_unit_ram_address_write;

        for i in 0 to nCores-1 loop
                result := result or unsigned(w_cores_output_cache_addresses(maxQubits*(nCores-i)-1 downto maxQubits*(nCores-i-1)));
        end loop;
           
        w_ram_address_write <= result;
    end process;
    
    
    process(w_cores_data_out, w_control_unit_ram_data_in) 
    variable result : std_logic_vector(precision-1 downto 0);
    begin
        result := w_control_unit_ram_data_in;

        for i in 0 to nCores-1 loop
                result := result or w_cores_data_out(precision*(nCores-i)-1 downto precision*(nCores-i-1)); 
        end loop;
            
        w_ram_data_in <= result;
    end process;
    
    
    w_ram_read_en <= w_ram_controller_ram_read_en or w_control_unit_ram_read_en;
    w_ram_write_en <= w_ram_controller_ram_write_en or w_control_unit_ram_write_en;
    
    w_program_memory_address <= w_program_counter or w_uartReceiver_program_memory_address_out;
    w_timer_reset <= reset_btn or w_control_unit_timer_reset or w_uartReceiver_reset_out;
    w_main_reset <= reset_btn or w_uartReceiver_reset_out;
    
    --ram controller
    w_ram_controller_reset <= w_main_reset or w_control_unit_ram_controller_reset;
    
end Behavioral;