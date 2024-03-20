library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

entity Timer is
Port ( 
    clk : in std_logic;
    count_enable : in std_logic;
    reset : in std_logic;
    seg: out std_logic_vector(6 downto 0);
    an: out std_logic_vector(3 downto 0);
    overflow: out std_logic_vector(15 downto 0)
    );
end Timer;

architecture Behavioral of Timer is

signal MUX_Signal: std_logic_vector(1 downto 0);
signal digit: std_logic_vector(3 downto 0);
signal clkdiv: std_logic_vector(20 downto 0);
signal counter: std_logic_vector(15 downto 0) := (others => '0');
signal overflow_reg: std_logic_vector(15 downto 0) := (others => '0');
-- tick_counter : std_logic_vector(8 downto 0) := (others => '0');

begin

count: process(clk, reset)
begin
    if reset = '1' then 
        counter <= (others => '0');
        overflow_reg <= (others => '0');
    
    elsif rising_edge(clk) then
        if count_enable = '1'then
            if counter = "1111111111111111" then
                overflow_reg <= overflow_reg + 1;
            end if;
            counter <= counter + 1;
        end if;
    end if;
end process;
    


 MUX: process(counter, MUX_Signal)
 begin
    case MUX_Signal is 
        when "00" => digit <= counter(3 downto 0);
        when "01" => digit <= counter(7 downto 4);
        when "10" => digit <= counter(11 downto 8);
        when others => digit <= counter(15 downto 12);
    end case;
 end process;
 
 
 encoder: process(digit)
 begin
    case digit is
    when X"0" => seg <= "1000000";
    when X"1" => seg <= "1111001";
    when X"2" => seg <= "0100100";
    when X"3" => seg <= "0110000";
    when X"4" => seg <= "0011001";
    when X"5" => seg <= "0010010";
    when X"6" => seg <= "0000010";
    when X"7" => seg <= "1011000";
    when X"8" => seg <= "0000000";
    when X"9" => seg <= "0010000";
    when X"A" => seg <= "0001000";
    when X"B" => seg <= "0000011";
    when X"C" => seg <= "1000110";
    when X"D" => seg <= "0100001";
    when X"E" => seg <= "0000110";
    when X"F" => seg <= "0001110";
    when others => seg <= "1000000";
    

    end case;
 end process;
 
 ancode: process(MUX_Signal)
 begin
    case MUX_Signal is 
        when "00" => an <= "1110";
        when "01" => an <= "1101";
        when "10" => an <= "1011";
        when others => an <= "0111";
     end case;
    
 end process;
 
 clock_divider: process(clk)
 begin
    if rising_edge(clk) then
        clkdiv <= clkdiv + 1;
    end if;
 end process;
 
 MUX_Signal <= clkdiv(20 downto 19);
 overflow <= overflow_reg;

end Behavioral;
