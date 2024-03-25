library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity uartTransmitter is
 generic (
          PRECISION : integer;
          CLOCK_FREQUENCY : integer;
          BAUD_RATE : integer);

  Port ( 
        clk : in std_logic; --clock
        tx_enable : in std_logic;
        tx : out std_logic := '1';
        tx_busy : out std_logic := '0';
        reset : in std_logic;
        data : in std_logic_vector(precision-1 downto 0));
        
end uartTransmitter;

    architecture Behavioral of uartTransmitter is
    -- clock cycles necessary to for transmitting one bit
    constant C_TICKS_PER_BIT : natural := CLOCK_FREQUENCY / BAUD_RATE; 
    
    --one packet always consists of one byte plus a start bit and an end bit
    constant C_BITS_PER_PACKET : natural := 10;
    
    --Number of packets needed to transmit one complex number. One packet consists of 8 Bits. 7 of them are used for data, one is used to indicate, that it is a data packet.
    constant C_PACKETS_PER_NUMBER : natural := (PRECISION+6) / 7; --(PRECISION+6) / 7 is effectively the same as round_up(PRECISION / 7)
     
    --start packet
    constant C_START_PACKET : std_logic_vector(7 downto 0) := "00000001";
    
    --end packet
    constant C_END_PACKET : std_logic_vector(7 downto 0) := "10000001";
    
    -- This signal is designed to accommodate data transmission requirements where only data with a bit width that is a multiple of 7 is permissible. To meet this specification, `resized_data` is defined with a bit width that aligns with the given requirements. 16 additional Bits are needed for the start and end packet. The signal is pre-filled with '0's to pad any unused bits, ensuring that the padding does not alter the interpreted value of the transmitted data on the receiver's end.
    signal resized_data : std_logic_vector(C_PACKETS_PER_NUMBER*7-1 downto 0) := (others => '0');
    
    -- Transmission control
    --counts clock cycles until one bit is sent
    signal tick_counter : natural range 0 to C_TICKS_PER_BIT := 0;
    
    --counts bits until one packet is sent
    signal bit_counter : natural range 0 to C_BITS_PER_PACKET + 1:= 0;
    
    --counts packets until the entire number is sent
    signal packet_counter : natural range 0 to C_PACKETS_PER_NUMBER + 3 := 0;
    
    --containts the current data packet and the additional start and stop bits
    signal shift_reg : std_logic_vector(9 downto 0) := (others => '1');

begin
    --resizing data
    resized_data(resized_data'length - 1 downto resized_data'length - PRECISION) <= data;
    
        process(clk)
        begin
        if rising_edge(clk) then
            
            --reset
            if reset = '1' then
                tick_counter <= 0;
                packet_counter <= 0;
                bit_counter <= 0;
                tx_busy <= '0'; 
                shift_reg <= (others => '1');
                
            else
                --check if component is still transmitting
                if packet_counter < (C_PACKETS_PER_NUMBER + 2) and tx_enable = '1' then
                    tx_busy <= '1';
                    --increment tick counter every clock cycle
                    if tick_counter < C_TICKS_PER_BIT then
                        tick_counter <= tick_counter + 1;
                    
                    --if tick counter is greater than or equal to C_TICKS_PER_BIT, it is reset to 0 and all transmission signals are set according to the next bit 
                    else
                        tick_counter <= 0;
                        if bit_counter = 0 then
                            if packet_counter = 0 then --transmit start packet 
                                shift_reg(9 downto 0) <= "1000000010";
                                bit_counter <= bit_counter + 1;
                            
                            elsif packet_counter = C_PACKETS_PER_NUMBER + 1 then --transmit end packet
                                shift_reg(9 downto 0) <= "1100000010";
                                bit_counter <= bit_counter + 1;
                            
                            else --transmit data packets
                                shift_reg(0) <= '0';
                                shift_reg(1) <= '0';
                                shift_reg(8 downto 2) <= resized_data(7*C_PACKETS_PER_NUMBER-1-(7*(packet_counter-1)) downto 7*C_PACKETS_PER_NUMBER-1-(7*(packet_counter-1))-6); --data
                                shift_reg(9) <= '1';
                                bit_counter <= bit_counter + 1;
                            end if;
                        
                        elsif bit_counter < C_BITS_PER_PACKET + 1 then --shift data in shift register if transmission of current packet has not finished
                            tx <= shift_reg(0);
                            shift_reg <= '1' & shift_reg(9 downto 1);
                            bit_counter <= bit_counter + 1;
                        else
                            packet_counter <= packet_counter + 1; --increment packet counter and reset bit_counter if transmission of current packet has finished
                            bit_counter <= 0;
                    
                    end if;
                            
                    end if;
                
                --set tx_busy to 0 when transmission has finished
                else
                    tx_busy <= '0';
                end if;       
            end if;  
        end if;
    end process;  
end Behavioral;