library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity ControlUnit is
    generic(
        maxQubits: integer;
        precision : integer;
        nCores : integer);     
    Port (
        clk : in std_logic;
        clk_rdy : in std_logic;
        reset : in std_logic;
        
        --instruction signals
        instruction : in unsigned(7 downto 0);
        program_counter_out : out unsigned(9 downto 0) := (others => '0');
        
        --processing
        target_qubit_out : out unsigned(3 downto 0) := (others => '0');      
        control_qubit_out : out unsigned(3 downto 0) := (others => '0');
        apply_control_gate_out : out std_logic := '0';
        target_matrix : out std_logic_vector(11 downto 0) := (others => '0');
        cores_reset : out std_logic := '0';
        
        --ram controller
        ram_controller_en : out std_logic := '0';
        nQubits_out : out unsigned(3 downto 0) := (others => '0');
        ram_controller_busy : in std_logic;
        ram_controller_reset : out std_logic := '0';
        
        --state Memory
        ram_write_enable : out std_logic := '0';
        ram_read_enable : out std_logic := '0';
        ram_address_read : out unsigned(maxQubits-1 downto 0) := (others => '0');
        ram_address_write : out unsigned(maxQubits-1 downto 0) := (others => '0');
        ram_data_in : out std_logic_vector(precision-1 downto 0) := (others => '0');
       
        --uart
        uartTransmit_busy : in std_logic;
        uartTransmit_reset : out std_logic := '0';
        uartTransmit_start : out std_logic := '0';
        
        --timer
        timer_reset : out std_logic := '0';
        timer_count_enable : out std_logic := '0'
    
    );
end ControlUnit;

architecture Behavioral of ControlUnit is
    --components

    --states
    type State is (FETCH, DECODE_EXECUTE);
    signal current_state : State := FETCH;
    
    --counters
    signal program_counter : unsigned(9 downto 0) := (others => '0');
    signal execution_cycles : integer range 0 to 15 := 0;
    
    --registers
    signal memory_address_reg  : unsigned(maxQubits downto 0) := (others => '0');
    signal state_vector_length_reg : unsigned(maxQubits downto 0) := (others => '0');
    
    --instruction registers
    signal op_code_reg : unsigned(3 downto 0):= (others => '0');
    signal op_param_reg : unsigned(3 downto 0):= (others => '0');
    
    --control signals  
    --uart

begin
    
    
    process (clk, reset, clk_rdy)
    begin
        if clk_rdy = '1' then
            if reset = '1' then
                --reset signals
                program_counter <= (others => '0');
                execution_cycles <= 0;
                op_code_reg <= (others => '0');
                op_param_reg <= (others => '0');
                current_state <= FETCH;
                target_matrix <= (others => '0');
                target_qubit_out <= (others => '0');
                nQubits_out <= (others => '0');
                state_vector_length_reg <= (others => '0');
                uartTransmit_reset <= '0';
                uartTransmit_start <= '0';
                memory_address_reg <= (others => '0');
                apply_control_gate_out <= '0';
                control_qubit_out <= (others => '0');
                timer_count_enable <= '0';
                timer_reset <= '0';
                cores_reset <= '0';
                ram_address_read <= (others => '0');
                ram_address_write <= (others => '0');
                ram_controller_en <= '0';
                ram_controller_reset <= '0';
                ram_data_in <= (others => '0');
                ram_read_enable <= '0';
                ram_write_enable <= '0';
                
    
            
            elsif rising_edge(clk) then
                if current_state = FETCH then
                    case execution_cycles is
                        when 0 =>
                            op_code_reg <= instruction(7 downto 4);
                            op_param_reg <= instruction(3 downto 0);
                            execution_cycles <= execution_cycles + 1;
                        when 1 =>
                            program_counter <= program_counter + 1;
                            execution_cycles <= 0;
                            current_state <= DECODE_EXECUTE;
                        
                        when others =>
                            Null; 
                        end case;
    
                        
                elsif current_state = DECODE_EXECUTE then
                    case op_code_reg is
                        when "0000" => --do nothing
                            current_state <= FETCH;
                        
                        when "0001" => --set number of qubits to simulate and calculate length of state vector
                            nQubits_out <= op_param_reg;
                            for i in 0 to maxQubits loop
                                if i = to_integer(op_param_reg) then
                                    state_vector_length_reg(i) <= '1';
                                end if;
                                
                            end loop;   
                            current_state <= FETCH;
                             
                        when "0010" => --set target qubit
                            target_qubit_out <= op_param_reg;
                            current_state <= FETCH;
                            
                        when "0011" => --set target matrix
                            case op_param_reg is
                                when "0001" =>
                                    target_matrix <= "011011011100";
                                when "0010" =>
                                    target_matrix <= "001000000101";
                                when others =>
                                    target_matrix <= "000001001000";
                            end case;
                            current_state <= FETCH;
                        
                       when "0100" => --update state vector
                            case execution_cycles is 
                                when 0 =>
                                    ram_controller_reset <= '1';
                                    cores_reset <= '1';
                                    execution_cycles <= execution_cycles + 1;
                                when 1 => 
                                    execution_cycles <= execution_cycles + 1;
                                when 2 =>
                                    ram_controller_reset <= '0';
                                    cores_reset <= '0';
                                    execution_cycles <= execution_cycles + 1; 
                                when 3 =>
                                    ram_controller_en <= '1';
                                    execution_cycles <= execution_cycles + 1; 
                                
                                when 4 =>
                                    execution_cycles <= execution_cycles + 1;
                                 
                                when 5 =>
                                    execution_cycles <= execution_cycles + 1;   
                                 
                                when 6 =>
                                    --wait till done calculating new state vector
                                    if ram_controller_busy = '0' then
                                        execution_cycles <= 0;
                                        current_state <= FETCH;
                                        ram_controller_en <= '0';
                                    end if;
                                    
                                when others =>
                                    null; 
                                    
                               end case;  
                       
                        
                        when "0111" => --send element of state vector over tx port
                            case execution_cycles is
                                when 0 =>
                                    execution_cycles <= execution_cycles + 1;
                                    ram_read_enable <= '1';
                                    ram_address_read <= memory_address_reg(maxQubits-1 downto 0);
                                    ram_address_write <= memory_address_reg(maxQubits-1 downto 0);
                                    uartTransmit_reset <= '1';
                                    --for resetting element in state vector (first element 1, all other elements 0):
                                    if to_integer(memory_address_reg) = 0 then
                                        ram_data_in <= "0100000000000000000000000000000000000000000000000000000000000000";
                                    else
                                        ram_data_in <= (others => '0');
                                    end if;
                                
                                when 1 =>
                                    execution_cycles <= execution_cycles + 1;
                                when 2 =>
                                    execution_cycles <= execution_cycles + 1;
                                    uartTransmit_reset <= '0';
                                    uartTransmit_start <= '1';
                                
                                when 3 =>
                                    execution_cycles <= execution_cycles + 1;
                                
                                when 4 =>
                                    if uartTransmit_busy = '1' then --wait till done sending
                                        NULL;
                                    else
                                       uartTransmit_start <= '0';
                                       ram_read_enable <= '0';
                                       uartTransmit_reset <= '1';
                                       execution_cycles <= execution_cycles + 1; 
                                        --reset element:
                                       if op_param_reg = "0000" then
                                            ram_write_enable <= '1';
                                       end if;
                                    end if;
                                    
                                when 5 =>
                                    execution_cycles <= execution_cycles + 1; 
             
                                when 6 =>
                                    if op_param_reg = "0000" then
                                        ram_write_enable <= '0';
                                    end if;
                                    uartTransmit_reset <= '0';
                                    ram_data_in <= (others => '0');
                                    ram_address_read <= (others => '0');
                                    ram_address_write <= (others => '0');
                                    execution_cycles <= 0;
                                    current_state <= FETCH;
                                    
                                when others =>
                                    Null;
                            end case;
                        
                        when "1000" => --set memory address register
                            case op_param_reg is
                                when "0000" => --set to 0
                                    memory_address_reg <= (others => '0');
                                    current_state <= FETCH;
                                    
                                when "0010" => --increment by one
                                    memory_address_reg <= memory_address_reg + 1;
                                    current_state <= FETCH;
                                when "0011" => --decrement by one
                                    memory_address_reg <= memory_address_reg - 1;
                                    current_state <= FETCH;
                                   
                                when others =>
                                    Null;
                            end case;
                        
                        when "1001" => --decrement program counter by op_adress if memory_adress_reg = 0 or memory_adress_reg >= 
                            case execution_cycles is
                                when 0 =>
                                    execution_cycles <= execution_cycles + 1;
                                    if  memory_address_reg < state_vector_length_reg then
                                        program_counter <= program_counter - resize(op_param_reg, program_counter'length);
                                    end if;
                                
                                when 1 =>
                                    execution_cycles <= 0;
                                    current_state <= FETCH;
                                
                                when others =>
                                    null;
                            end case;
                        
                        when "1011" =>--halt
                            Null;  
                            
                        when "1100" => --timer
                            case op_param_reg is
                                when "0000" =>--reset timer
                                    case execution_cycles is
                                        when 0 =>
                                            timer_reset <= '1';
                                            execution_cycles <= execution_cycles + 1;
                                        when 1 =>
                                            execution_cycles <= execution_cycles + 1;
                                        when 2 =>
                                            timer_reset <= '0';
                                            execution_cycles <= 0;
                                            current_state <= FETCH;
                                            
                                        when others =>
                                            null;
                                    end case;         
                                    
                                when "0001" => --start timer
                                    timer_count_enable <= '1';
                                    current_state <= FETCH;
                                    
                                when "0010" =>--stop timer
                                    timer_count_enable <= '0';
                                    current_state <= FETCH;
                                    
                                when others =>
                                    null;
                            end case;
                        
                        when "1101" => --set control qubit to parameter
                            control_qubit_out <= op_param_reg;
                            apply_control_gate_out <= '1';
                            current_state <= FETCH;
                            
                        when "1110" => --deactivate "apply control gate"
                            apply_control_gate_out <= '0';
                            current_state <= FETCH;
                        
                        when others =>
                            current_state <= FETCH;
                     end case;      
                end if; 
            end if;
        end if;
    end process;

    program_counter_out <= program_counter;
    
end Behavioral;

