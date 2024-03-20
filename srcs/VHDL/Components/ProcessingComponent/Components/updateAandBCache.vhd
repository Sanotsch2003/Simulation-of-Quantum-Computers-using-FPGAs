library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity updateAandBCache is
   Port (
        clk : in std_logic;
        reset : in std_logic;
        write_en : in std_logic;
        update_a_in : in std_logic;
        update_b_in : in std_logic;
        update_a_out : out std_logic;
        update_b_out : out std_logic
        );
        
end updateAandBCache;

architecture Behavioral of updateAandBCache is
    signal update_a_reg : std_logic := '0';
    signal update_b_reg : std_logic := '0';
    
begin
    process(clk)
    
    begin
        if rising_edge(clk) then
            if reset = '1' then
                update_a_reg <= '0';
                update_b_reg <= '0';
            else
                if write_en = '1' then
                    update_a_reg <= update_a_in;
                    update_b_reg <= update_b_in;
                end if;
            end if;
           
        end if;
    
    end process;
    update_a_out <= update_a_reg;
    update_b_out <= update_b_reg;
    
end Behavioral;
