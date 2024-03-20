library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity adressTempCache is
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
        
end adressTempCache;

architecture Behavioral of adressTempCache is
    signal adress_a_reg :  std_logic_vector(maxQubits-1 downto 0) := (others => '0');
    signal adress_b_reg :  std_logic_vector(maxQubits-1 downto 0) := (others => '0');
    
begin
    process(clk)
    
    begin
        if rising_edge(clk) then
            if reset = '1' then
                adress_a_reg <= (others => '0');
                adress_b_reg <= (others => '0');
            else
                if write_en = '1' then
                    adress_a_reg <= adress_a_in;
                    adress_b_reg <= adress_b_in;
                end if;
            end if;
           
        end if;
    
    end process;
    adress_a_out <= adress_a_reg;
    adress_b_out <= adress_b_reg;
    
end Behavioral;
