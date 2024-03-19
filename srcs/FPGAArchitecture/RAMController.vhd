library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity RAMController is
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
        
        RAM_write_enable : out std_logic := '0';
        RAM_read_enable : out std_logic := '0';
        
        core_write_addresses_to_temp_cache_en : out std_logic_vector(nCores-1 downto 0) := (others => '0');
        core_cacheUpdateAandB_enables : out std_logic_vector(nCores-1 downto 0) := (others => '0');
        core_enables : out std_logic_vector(nCores - 1 downto 0) := (others => '0');
        core_cache_read_addresses_en : out std_logic_vector(4*nCores-1 downto 0) := (others => '0');
        core_cache_write_data_en : out std_logic_vector(2*nCores-1 downto 0) := (others => '0');
        core_cache_read_data_en :  out std_logic_vector(2*nCores-1 downto 0) := (others => '0');
        core_indices_out : out std_logic_vector(maxQubits*nCores-1 downto 0) := (others => '0');
        cores_ready : in std_logic_vector(nCores-1 downto 0)
   );
end RAMController;

    architecture Behavioral of RAMController is

    signal current_write_core : integer range 0 to nCores - 1 := 0; --signal that determines which core is allowed to write to ram next
    signal current_read_core : integer range 0 to nCores - 1 := 0; --signal that determines which core is allowed to read from ram next
    
    --keeps track steps within reading and writing operations
    signal current_read_cycle : integer range 0 to 7 := 0;
    signal current_write_cycle : integer range 0 to 7 := 0;
    
    --initilization
    signal initialized : boolean := False;
    signal cores_rdy_reference : std_logic_vector(nCores-1 downto 0) := (others => '0');
    signal initialization_cycles : integer range 0 to 3 := 0;
    signal iterations_needed : unsigned(maxQubits downto 0) := (others => '0');
    signal done_writing_to_cores : boolean := False;
    signal buffer_busy : std_logic := '0';
        
    --keeps track of indices
    signal times_written_to_ram : unsigned(maxQubits-1 downto 0) := (others => '0');
    signal times_read_from_ram : unsigned(maxQubits-1 downto 0) := (others => '0');
    signal current_index : unsigned(maxQubits-1 downto 0) := (others => '0');
    
begin
    process(clk)
    begin
    
        if (rising_edge(clk)) then
            if reset = '1' then
                buffer_busy <= '0';
                done_writing_to_cores <= False;
                
                current_write_core <= 0;
                current_read_core <= 0;
                
                current_read_cycle <= 0;
                current_write_cycle <= 0;
                
                RAM_write_enable <= '0';
                RAM_read_enable <= '0';
                
                core_cache_read_addresses_en <= (others => '0');
                core_cache_write_data_en <= (others => '0');
                core_enables <= (others => '0');
                core_cache_read_data_en <= (others => '0');
                
                initialized <= False;
                initialization_cycles <= 0;
                iterations_needed <= (others => '0');
                times_written_to_ram <= (others => '0');
                times_read_from_ram <= (others => '0');
                core_cacheUpdateAandB_enables <= (others => '0');
                cores_set_output_statuses <= (others => '0');
                cores_set_input_statuses <= (others => '0');
                
                cores_rdy_reference <= (others => '0');
     
                
            elsif enable = '1' then
                --check if controller has been initialized
                if initialized = False then
                    case initialization_cycles is
                    
                    when 0 => 
                        --calculate iterations needed
                        for i in 0 to maxQubits loop
                            if i = to_integer(nQubits_in-1) then
                                iterations_needed(i) <= '1';
                            end if;
                            
                        end loop;
                        cores_set_output_statuses <= (others => '1');
                        --set necessary signals
                        buffer_busy <= '1'; 
                        initialization_cycles <= initialization_cycles + 1;
                        
                    
                    when 1 =>
                        initialization_cycles <= initialization_cycles + 1;
                        
                    when 2 =>
                        initialization_cycles <= initialization_cycles + 1;
                        --set start indices for all cores and enable them
                        for i in 0 to nCores - 1 loop
                            if i < to_integer(iterations_needed) then
                                core_indices_out(maxQubits*(nCores-i)-1 downto maxQubits*(nCores-i-1)) <= std_logic_vector(to_unsigned(i, maxQubits));
                                core_enables(nCores-1-i) <= '1';
                                cores_rdy_reference(nCores-1-i) <= '1';  
                            
                            end if;
                        end loop;
                        current_index <= to_unsigned(nCores - 1, maxQubits);
                    
                    when 3 =>
                        if cores_ready = cores_rdy_reference then
                            cores_set_output_statuses <= (others => '0');
                            initialized <= True;
                        else
                            null;
                        end if;
                    
                    when others =>
                        null;
                    
                    end case;
       
                else
                
                    --write to core cache
                    if done_writing_to_cores = False and cores_input_statuses((nCores-current_write_core)*2-1 downto (nCores-current_write_core-1)*2) = "10" then --check if core input cache is rdy to be written to 
                        if current_write_cycle = 0 then
                            core_cacheUpdateAandB_enables(nCores-current_write_core-1) <= '1'; --tell core to read current updata_a_and_b parameters into cache
                            core_write_addresses_to_temp_cache_en(nCores-current_write_core-1) <= '1'; --tell core to write current addresses to output cache
                            --start writing to first cache
                            core_cache_read_addresses_en((nCores-current_write_core)*4-1) <= '1'; 
                            core_cache_write_data_en((nCores-current_write_core)*2-1) <= '1';
                            RAM_read_enable <= '1';
                            current_write_cycle <= current_write_cycle + 1;
                        
                        elsif current_write_cycle = 1 then
                            current_write_cycle <= current_write_cycle + 1;
                            
                        elsif current_write_cycle = 2 then
                            current_write_cycle <= current_write_cycle + 1;
                        
                        elsif current_write_cycle = 3 then
                            --set control signals back to zero
                            core_cacheUpdateAandB_enables(nCores-current_write_core-1) <= '0';
                            core_write_addresses_to_temp_cache_en(nCores-current_write_core-1) <= '0';
                        
                            --end writing to first cache and start writing to second cache
                            core_cache_read_addresses_en((nCores-current_write_core)*4-1) <= '0'; 
                            core_cache_write_data_en((nCores-current_write_core)*2-1) <= '0';
                            
                            core_cache_read_addresses_en((nCores-current_write_core)*4-2) <= '1'; 
                            core_cache_write_data_en((nCores-current_write_core)*2-2) <= '1';
                            current_write_cycle <= current_write_cycle + 1;
                        
                        elsif current_write_cycle = 4 then
                            current_write_cycle <= current_write_cycle + 1;
                            
                        elsif current_write_cycle = 5 then
                            current_write_cycle <= current_write_cycle + 1;
                        
                        elsif current_write_cycle = 6 then
                            --end writing to second cache
                            core_cache_read_addresses_en((nCores-current_write_core)*4-2) <= '0'; 
                            core_cache_write_data_en((nCores-current_write_core)*2-2) <= '0';
                            RAM_read_enable <= '0';
                            cores_set_input_statuses(nCores-current_write_core-1) <= '1'; --tell core that data is now in cache
                            current_write_cycle <= current_write_cycle + 1;
                            
                        
                        elsif current_write_cycle = 7 then
                        
                            cores_set_input_statuses(nCores-current_write_core-1) <= '0'; --tell core that data is now in cache
                            if times_read_from_ram = (iterations_needed-1) then
                                done_writing_to_cores <= True;
                            else
                                times_read_from_ram <= times_read_from_ram + 1;
                                current_index <= current_index + 1;
                                core_indices_out(maxQubits*(nCores-current_write_core)-1 downto maxQubits*(nCores-current_write_core-1)) <= std_logic_vector(current_index + 1);
                            
                            end if;
                                                    
                            if current_write_core < nCores - 1 then
                               current_write_core <= current_write_core + 1;
                            else
                               current_write_core <= 0;
                            end if; 
                            
                            current_write_cycle <= 0;
                        
                        end if;
                    
                    else
                        if current_write_core < nCores - 1 then
                            current_write_core <= current_write_core + 1;
                        else
                            current_write_core <= 0;
                        end if;  
                        
                    end if;
                    
                    
                    --read from core cache
                    if buffer_busy = '1' and cores_output_statuses((nCores-current_read_core)*2-1 downto (nCores-current_read_core-1)*2) = "10" then --check if core input cache is rdy to be read from
                         if current_read_cycle = 0 then
                            --start reading from first cache
                            core_cache_read_addresses_en((nCores-current_read_core)*4-3) <= '1'; 
                            core_cache_read_data_en((nCores-current_read_core)*2-1) <= '1';
                            current_read_cycle <= current_read_cycle + 1;
                        
                        elsif current_read_cycle = 1 then
                            current_read_cycle <= current_read_cycle + 1; 
                        
                        elsif current_read_cycle = 2 then
                            current_read_cycle <= current_read_cycle + 1; 
                            RAM_write_enable <= '1';
                            
                        elsif current_read_cycle = 3 then
                            current_read_cycle <= current_read_cycle + 1; 
                            RAM_write_enable <= '0';
                        
                        elsif current_read_cycle = 4 then
                            --end reading from first cache and start reading from second cache
                            core_cache_read_addresses_en((nCores-current_read_core)*4-3) <= '0'; 
                            core_cache_read_data_en((nCores-current_read_core)*2-1) <= '0';
                            
                            core_cache_read_addresses_en((nCores-current_read_core)*4-4) <= '1'; 
                            core_cache_read_data_en((nCores-current_read_core)*2-2) <= '1';
                            current_read_cycle <= current_read_cycle + 1;
                        
                        elsif current_read_cycle = 4 then 
                            current_read_cycle <= current_read_cycle + 1;  
                            
                        elsif current_read_cycle = 5 then 
                            current_read_cycle <= current_read_cycle + 1; 
                            RAM_write_enable <= '1';
                            
                        elsif current_read_cycle = 6 then
                            current_read_cycle <= current_read_cycle + 1; 
                            RAM_write_enable <= '0';  
                            cores_set_output_statuses(nCores-current_read_core-1) <= '1';
                        
                        elsif current_read_cycle = 7 then
                            --end reading from second cache
                            core_cache_read_addresses_en((nCores-current_read_core)*4-4) <= '0'; 
                            core_cache_read_data_en((nCores-current_read_core)*2-2) <= '0';
                            RAM_write_enable <= '0';
                            
                            cores_set_output_statuses(nCores-current_read_core-1) <= '0'; 
                            
                            times_written_to_ram <= times_written_to_ram + 1;
                            
                            
                            if times_written_to_ram = (iterations_needed-1) then
                                buffer_busy <= '0';  
                                core_enables <= (others => '0');
                            end if;
                            
                            if current_read_core < nCores - 1 then
                               current_read_core <= current_read_core + 1;
                            else
                               current_read_core <= 0;
                            end if; 
                            
                            current_read_cycle <= 0;
                            
                        
                        end if;
                        
                    else
                        if current_read_core < nCores - 1 then
                            current_read_core <= current_read_core + 1;
                        else
                            current_read_core <= 0;
                        end if; 
                        
                    end if;
                    
                end if;
                   
            else 
                null;
            end if;
        end if;
        
    end process;
    
    busy <= buffer_busy;
    
end Behavioral;
