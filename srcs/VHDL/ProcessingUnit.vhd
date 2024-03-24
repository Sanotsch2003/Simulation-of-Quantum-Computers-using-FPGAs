library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity processingCore is
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
end processingCore;

architecture Behavioral of processingCore is

--registers
signal execution_cycles_reg : integer range 0 to 15 := 0;

--wires
signal w_index_a : std_logic_vector(maxQubits-1 downto 0);
signal w_index_b : std_logic_vector(maxQubits-1 downto 0);

signal w_v_a_not_updated : std_logic_vector(precision-1 downto 0);
signal w_v_b_not_updated : std_logic_vector(precision-1 downto 0);

signal w_v_a_updated : std_logic_vector(precision-1 downto 0);
signal w_v_b_updated : std_logic_vector(precision-1 downto 0);

signal w_update_a_enable_to_cache : std_logic;
signal w_update_b_enable_to_cache : std_logic;
signal w_update_a_enable_to_alu : std_logic;
signal w_update_b_enable_to_alu : std_logic;

signal input_status_reg : std_logic_vector(1 downto 0) := "00";
signal output_status_reg : std_logic_vector(1 downto 0) := "00";

signal w_set_input_status_internal : std_logic := '0';
signal w_set_output_status_internal : std_logic := '0';

signal w_write_data_to_output_cache : std_logic  := '0';
signal w_write_addresses_to_output_cache : std_logic  := '0';

signal w_input_cache_a_address_out : std_logic_vector(maxQubits-1 downto 0);
signal w_input_cache_b_address_out : std_logic_vector(maxQubits-1 downto 0);
signal w_output_cache_a_address_out : std_logic_vector(maxQubits-1 downto 0);
signal w_output_cache_b_address_out : std_logic_vector(maxQubits-1 downto 0);

signal w_adress_temp_cache_a_out : std_logic_vector(maxQubits-1 downto 0);
signal w_adress_temp_cache_b_out : std_logic_vector(maxQubits-1 downto 0);

signal w_output_cache_a_data_out : std_logic_vector(precision-1 downto 0);
signal w_output_cache_b_data_out : std_logic_vector(precision-1 downto 0);

signal initialized : std_logic := '0';
signal initialization_cycle : integer range 0 to 4 := 0;

component getVaAndVb is
            generic(
                    maxQubits: integer
                    );
            Port (
                n : in unsigned(maxQubits-1 downto 0);
                target : in unsigned(3 downto 0);
                a_out : out std_logic_vector(maxQubits-1 downto 0);
                b_out : out std_logic_vector(maxQubits-1 downto 0);
                update_a_enable : out std_logic;
                update_b_enable : out std_logic;
                control_qubit : in unsigned(3 downto 0);
                apply_control_gate : in std_logic
                );
     end component;

component updateAandBcache is
        Port(
            clk : in std_logic;
            reset : in std_logic;
            write_en : in std_logic;
            update_a_in : in std_logic;
            update_b_in : in std_logic;
            update_a_out : out std_logic;
            update_b_out : out std_logic
        );
        end component;
   
component ALU is 
    generic(
          precision: integer
          );
          
     Port ( 
           v_a_in: in std_logic_vector(precision-1 downto 0);
           v_b_in: in std_logic_vector(precision-1 downto 0);
           matrix_in: in std_logic_vector(11 downto 0);
           v_a_out : out std_logic_vector(precision-1 downto 0);
           v_b_out : out std_logic_vector(precision-1 downto 0);
           update_a_enable : in std_logic;
           update_b_enable : in std_logic
           
          );
     end component;
     
component adressTempCache is
       generic(
              maxQubits: integer:=14
            );
       Port (
            clk : in std_logic;
            reset : in std_logic;
            write_en : in std_logic;
            adress_a_in : in std_logic_vector(maxQubits-1 downto 0);
            adress_b_in : in std_logic_vector(maxQubits-1 downto 0);
            adress_a_out : out std_logic_vector(maxQubits-1 downto 0);
            adress_b_out : out std_logic_vector(maxQubits-1 downto 0)
            );
end component;


component coreCache is
 Generic(
            precision: integer:=64; 
            maxQubits: integer:=14
    );
 Port (
        clk: in std_logic;
        reset: in std_logic;
        address_in: in std_logic_vector(maxQubits-1 downto 0);
        address_out: out std_logic_vector(maxQubits-1 downto 0);
        write_address_en : in std_logic;
        read_address_en : in std_logic;
        data_in : in std_logic_vector(precision-1 downto 0);
        data_out : out std_logic_vector(precision-1 downto 0);
        write_data_en : in std_logic;
        read_data_en : in std_logic
        
  );
end component;

begin
    indexCalculation : getVaAndVb
    generic map(
                maxQubits => maxQubits
                )
     port map(
            n => index,
            target => target_qubit,
            a_out => w_index_a,
            b_out => w_index_b,
            update_a_enable => w_update_a_enable_to_cache,
            update_b_enable => w_update_b_enable_to_cache,
            control_qubit => control_qubit,
            apply_control_gate => control_enable
            );
    
    cachUpdateAandB : updateAandBCache
    port map(
            clk => clk,
            reset => reset,
            write_en => cacheUpdateAandB_en,
            update_a_in => w_update_a_enable_to_cache,
            update_b_in => w_update_b_enable_to_cache,
            update_a_out => w_update_a_enable_to_alu,
            update_b_out => w_update_b_enable_to_alu
            );
       
    elementUpdating : ALU
    generic map(
                precision => precision
                )
    port map(
            v_a_in => w_v_a_not_updated,
            v_b_in => w_v_b_not_updated,
            matrix_in => target_matrix,
            v_a_out => w_v_a_updated,
            v_b_out => w_v_b_updated,
            update_a_enable => w_update_a_enable_to_alu,
            update_b_enable => w_update_b_enable_to_alu
            );
            
    inputCache_a : coreCache
    generic map(
                precision => precision,
                maxQubits => maxQubits
                )
     port map(
            clk => clk,
            reset => reset,
            address_in => w_index_a,
            address_out => w_input_cache_a_address_out,
            write_address_en => '1',
            read_address_en => cache_read_addreses_en(3),
            data_in => cache_data_in,
            data_out => w_v_a_not_updated,
            write_data_en => cache_write_data_en(1),
            read_data_en => '1'
            );
            
    inputCache_b : coreCache
    generic map(
                precision => precision,
                maxQubits => maxQubits
                )
     port map(
            clk => clk,
            reset => reset,
            address_in => w_index_b,
            address_out => w_input_cache_b_address_out,
            write_address_en => '1',
            read_address_en => cache_read_addreses_en(2),
            data_in => cache_data_in,
            data_out => w_v_b_not_updated,
            write_data_en => cache_write_data_en(0),
            read_data_en => '1');
    
    adressesTempCache : adressTempCache 
       generic map(
              maxQubits => maxQubits
            )
       Port map(
            clk => clk,
            reset => reset,
            write_en => write_addresses_to_temp_cache_en,
            adress_a_in => w_index_a,
            adress_b_in => w_index_b,
            adress_a_out => w_adress_temp_cache_a_out,
            adress_b_out => w_adress_temp_cache_b_out
            );
          
    outputCache_a : coreCache
    generic map(
                precision => precision,
                maxQubits => maxQubits
                )
     port map(
            clk => clk,
            reset => reset,
            address_in => w_adress_temp_cache_a_out,
            address_out => w_output_cache_a_address_out,
            write_address_en => w_write_addresses_to_output_cache,
            read_address_en => cache_read_addreses_en(1),
            data_in => w_v_a_updated,
            data_out => w_output_cache_a_data_out,
            write_data_en => w_write_data_to_output_cache,
            read_data_en => cache_read_data_en(1)
            );
            
    outputCache_b : coreCache
    generic map(
                precision => precision,
                maxQubits => maxQubits
                )
     port map(
            clk => clk,
            reset => reset,
            address_in => w_adress_temp_cache_b_out,
            address_out => w_output_cache_b_address_out,
            write_address_en => w_write_addresses_to_output_cache,
            read_address_en => cache_read_addreses_en(0),
            data_in => w_v_b_updated,
            data_out => w_output_cache_b_data_out,
            write_data_en => w_write_data_to_output_cache,
            read_data_en => cache_read_data_en(0)
            );
    
    
    process(clk)
    begin
    if (rising_edge(clk)) then
        if (reset = '1') then
            execution_cycles_reg <= 0;
            initialized <= '0';
            initialization_cycle <= 0;
            w_set_input_status_internal <= '0';
            w_set_input_status_internal <= '0';
            input_status_reg <= "00";
            output_status_reg <= "00";
            w_write_data_to_output_cache <= '0';
            w_write_addresses_to_output_cache <= '0';
      
        elsif (enable = '1') then
            if initialized = '0' then
                case initialization_cycle is
                --wait for first two indices to be available as adresses in input cache and set input control signals to tell ram controller that data is rdy to be written to input cache
                when 0 =>
                    initialization_cycle <= initialization_cycle + 1;
                when 1 =>
                    initialization_cycle <= initialization_cycle + 1;
                when 2 =>
                    initialized <= '1';
                    input_status_reg <= "10";
                    
                when others =>
                    null;
                end case;
            
            else
                --set input status signals
                if w_set_input_status_internal = '1' and set_input_status_external = '0' then
                    input_status_reg <= "10";
                    
                elsif w_set_input_status_internal = '0' and set_input_status_external = '1' then
                    input_status_reg <= "01";

                end if;
                
                --set ouput status signals
                if w_set_output_status_internal = '1' and set_output_status_external = '0' then
                    output_status_reg <= "10";
                    
                elsif w_set_output_status_internal = '0' and set_output_status_external = '1' then
                    output_status_reg <= "01";

                end if;
                
                --check if data has arrived in input cache and process it
                if input_status_reg = "01" then
                    case execution_cycles_reg is
                    when 0 =>
                        execution_cycles_reg <= execution_cycles_reg + 1;
                    
                    when 1 =>
                        execution_cycles_reg <= execution_cycles_reg + 1;
                        
                    when 2 =>
                        execution_cycles_reg <= execution_cycles_reg + 1;
                    
                    when 3 =>
                        if output_status_reg = "01" then  --check if output cache is rdy
                            w_write_data_to_output_cache <= '1';
                            w_write_addresses_to_output_cache <= '1';
                            execution_cycles_reg <= execution_cycles_reg + 1;
                        else
                            null;
                        end if;
                        
                    when 4 =>
                        execution_cycles_reg <= execution_cycles_reg + 1;
                    when 5 =>
                        w_set_input_status_internal <= '1';
                        w_set_output_status_internal <= '1'; 
                        w_write_data_to_output_cache <= '0';
                        w_write_addresses_to_output_cache <= '0';
                        execution_cycles_reg <= 0;
                    
                    when others =>
                    
                    end case;
                
                else
                     w_set_input_status_internal <= '0';
                     w_set_output_status_internal <= '0';
                end if;
                
            end if;
        else
            Null;
        
        end if;
        
    end if;
    end process;
    
    input_cache_address <= w_input_cache_a_address_out or w_input_cache_b_address_out;
    output_cache_address <= w_output_cache_a_address_out or w_output_cache_b_address_out;
    cache_data_out <= w_output_cache_a_data_out or w_output_cache_b_data_out;
    ready <= initialized; 
    input_status_out <= input_status_reg;
    output_status_out <= output_status_reg;
    
    
end Behavioral;
