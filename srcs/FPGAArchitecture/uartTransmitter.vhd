library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity uartTransmitter is
 generic (
          precision : integer;
          clockFrequency : integer;
          baudRate : integer);

  Port ( 
        clk : in std_logic; --clock
        tx_start : in std_logic;
        tx : out std_logic := '1';
        tx_busy : out std_logic := '0';
        reset : in std_logic;
        data : in std_logic_vector(precision-1 downto 0));
        
end uartTransmitter;

    architecture Behavioral of uartTransmitter is
        -- Baud rate generation
    constant ticks_per_bit : integer := clockFrequency / baudRate; --clock frequency devided by baud rate
    
    signal tick_counter : integer range 0 to ticks_per_bit := 0;
    
    --data
    --signal tx_data_complex_in : std_logic_vector(precision-1 downto 0) := "0010110101000001001111001100110011010010101111101100001100110011";
    signal resized_data : std_logic_vector(69 downto 0) := (others => '0');
    
    -- Transmission control
    signal current_frame : integer range 0 to 13 := 0;
    signal current_bit : integer range 0 to 13 := 0;  -- 1 start bit, 8 data bits, 1 stop bit
    signal shift_reg : std_logic_vector(9 downto 0) := (others => '1');
begin
    resized_data <= data & "000000";
    process(clk)
        begin
        if rising_edge(clk) then
            
            if current_frame < 12 and tx_start = '1' then
                tx_busy <= '1';
            else
                tx_busy <= '0';
            end if;
            
            if reset = '1' then
                tick_counter <= 0;
                current_frame <= 0;
                current_bit <= 0; 
                shift_reg <= (others => '1');
                
            
            elsif tick_counter < ticks_per_bit then
                tick_counter <= tick_counter + 1;
            else
                tick_counter <= 0;
                if tx_start = '1' then 
                    if current_frame < 12 then
                    
                        if current_bit = 0 then
                            if current_frame = 0 then
                                shift_reg(9 downto 0) <= "1000000010";
                                current_bit <= current_bit + 1;
                            
                            elsif current_frame = 11 then
                                shift_reg(9 downto 0) <= "1100000010";
                                current_bit <= current_bit + 1;
                            
                            else
                                shift_reg(0) <= '0';
                                shift_reg(1) <= '0';
                                shift_reg(8 downto 2) <= resized_data(70-1-(7*(current_frame-1)) downto 70-1-(7*(current_frame-1))-6); --data
                                shift_reg(9) <= '1';
                                current_bit <= current_bit + 1;
                            end if;
                        
                        elsif current_bit < 11 then
                            tx <= shift_reg(0);
                            shift_reg <= '1' & shift_reg(9 downto 1);
                            current_bit <= current_bit + 1;
                        else
                            current_frame <= current_frame + 1;
                            current_bit <= 0;
                        
                        end if;  
                    end if;
                end if;
            end if;
        end if;
    end process;
    
  
end Behavioral;