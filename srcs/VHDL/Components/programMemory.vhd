library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ProgramMemory is

    port (
        clk : in std_logic; --only reads on positive edge of this signal
        address_read : in unsigned(9 downto 0); -- Address input for reading    -- Data output
        data_out : out unsigned(7 downto 0);
        data_in: in unsigned(7 downto 0);
        write_enable : in std_logic
    );
end entity ProgramMemory;

architecture Behavioral of ProgramMemory is
    type MemoryArray is array (0 to 1023) of unsigned(7 downto 0);
    signal memory : MemoryArray := (
                                    0 => "00000000", --do nothing
                                    1 => "11000000", --reset timer
                                    2 => "11000001", --start time
                                    3 => "00011110", --set nQubits to 14
                                    4 => "00100001", --set target Qubit to 1
                                    5 => "00110001", --set target matrix to h
                                    6 => "01000000", --enable ram/core controller 
                                    7 => "11000010", --stop timer
                                    8 => "01110000", --send number via uart
                                    9 => "10000010", --increment ram address register
                                    10 => "10010011", --decrement program counter by 3 
                                    11 => "10110000", --halt
                                    others => (others => '0'));

begin
 
    read: process(clk)
    begin
        if rising_edge(clk) then
            if write_enable = '1' then
                memory(to_integer(address_read)) <= data_in;
            end if;
            data_out <= memory(to_integer(address_read));
        end if;
    end process;  

end architecture Behavioral;
