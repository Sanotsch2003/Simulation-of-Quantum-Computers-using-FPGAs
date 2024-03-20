library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;


entity RAM is
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
end RAM;

architecture Behavioral of RAM is
    type memory_array is array (0 to 2**maxQubits-1) of std_logic_vector(precision-1 downto 0);
    signal memory : memory_array := (0 => "0100000000000000000000000000000000000000000000000000000000000000",

                                     others => (others => '0'));
begin
    process(clk)
    begin
        if rising_edge(clk) then
        
            if write_enable = '1' then
            -- Write data to RAM
                memory(to_integer(unsigned(address_write))) <= data_in;
            end if;
    
            if read_enable = '1' then
                -- Read data from RAM
                data_out <= memory(to_integer(unsigned(address_read)));
            else
                data_out <= (others => '0');
                
                
            end if;

        end if;
    end process;
end Behavioral;
