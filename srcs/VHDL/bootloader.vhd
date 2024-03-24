library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity bootloader is
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
end bootloader;

architecture Behavioral of bootloader is 
    type state is (RECEIVING, PROCESSING);
    signal current_state : State := RECEIVING; 
    
    --signals used for receiving data
    type receiving_state is (IDLE, RECEIVING_DATA);
    signal current_receiving_state : receiving_state := IDLE; 
    
    constant ticks_per_bit : integer := clk_frequency / baud_rate; --clock frequency devided by baud rate
    signal tick_counter : integer range 0 to ticks_per_bit := 0;
    signal bit_counter : integer range 0 to 9 := 0;
    signal data_reg : unsigned(7 downto 0) := (others => '0');
    
    --signals used for processing data
    type processing_state is (IDLE, WRITING_PROGRAM);
    signal current_processing_state : processing_state := IDLE;
    signal processing_cycles : integer range 0 to 15 := 0;
    signal program_memory_address_reg : unsigned(instruction_address_width-1 downto 0) := (others => '0');
    signal w_reset: std_logic := '0';
    
    
    
    begin
        
        test: process(clk)
        begin
            if rising_edge(clk) then
                if current_state = RECEIVING then
                    if current_receiving_state = IDLE and rx = '0' then --check for start bit
                        current_receiving_state <= RECEIVING_DATA;
                        tick_counter <= 0;
                        bit_counter <= 0;
                        
                    elsif tick_counter >= ticks_per_bit then
                        tick_counter <= 0;
                        if bit_counter < 9 then
                            bit_counter <= bit_counter + 1;
                        
                        --done receiving one byte
                        else
                            bit_counter <= 0;
                            current_receiving_state <= IDLE;
                            current_state <= PROCESSING;
                        end if;
                        
                    elsif current_receiving_state = RECEIVING_DATA then
                        tick_counter <= tick_counter + 1;
                        
                    end if;
                    
                    if tick_counter = ticks_per_bit/2 and not (bit_counter = 0 or bit_counter = 9) then
                        data_reg(bit_counter-1) <= rx;       
                    end if;
                
                elsif current_state = PROCESSING then
                    -- if the processing state is IDLE the bootloader will only react to "11111111"
                    if current_processing_state = IDLE then
                        if data_reg = "11111111" then --start writing to program Memory
                            w_reset <= '1';
                            current_state <= RECEIVING;
                            current_processing_state <= WRITING_PROGRAM;
                            program_memory_address_reg <= (others => '0');
                        else
                            current_state <= RECEIVING;
                            program_memory_address_reg <= (others => '0');
                        end if;
                        
                    elsif current_processing_state = WRITING_PROGRAM then
                         if data_reg = "11111111" then --end writing to program Memory
                            w_reset <= '0';
                            current_state <= RECEIVING;
                            current_processing_state <= IDLE;
                            program_memory_address_reg <= (others => '0');
                         else
                            case processing_cycles is 
                            
                            when 0 =>
                                program_memory_write_enable <= '1';
                                processing_cycles <= processing_cycles + 1;
                            when 1 =>
                                processing_cycles <= processing_cycles + 1;
                            
                            when 2 =>
                                program_memory_write_enable <= '0';
                                program_memory_address_reg <= program_memory_address_reg + 1;
                                processing_cycles <= 0;
                                current_state <= RECEIVING;
                            when others =>
                                null;
                            
                            end case;
                            
                         end if;
                    end if;
                    
                    
                end if;
                
            end if;
        
        end process;
        program_memory_address <= program_memory_address_reg;
        program_memory_data_in <= data_reg;
        reset <= w_reset;
end Behavioral;
