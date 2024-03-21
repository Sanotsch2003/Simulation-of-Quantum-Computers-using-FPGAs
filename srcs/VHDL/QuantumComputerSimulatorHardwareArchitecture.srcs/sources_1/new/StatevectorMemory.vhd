-- Importing the necessary libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL; -- Standard Logic Package
use IEEE.NUMERIC_STD.ALL; -- Numeric Standard Package

-- Defining the entity StatevectorMemory
entity StatevectorMemory is
  -- Generic parameters for the entity
  Generic(
          precision : integer; -- Precision of the data
          maxQubits : integer; -- Maximum number of qubits
          nCores : integer -- Number of cores
          );
          
  -- Port declaration for the entity
    Port (clk : in std_logic; -- Clock signal
        reset : in std_logic; -- Reset signal
        write_en : in std_logic; -- Write enable signal
        read_en : in std_logic; -- Read enable signal

        -- address_read and address_write point to the first element of the memory that needs to be read/updated
        address_read : in std_logic_vector(maxQubits-1 downto 0); -- Read address of the memory
        address_write : in std_logic_vector(maxQubits-1 downto 0); -- Write address of the memory

        data_in : in std_logic_vector(precision*nCores-1 downto 0); -- Input data
        data_out : out std_logic_vector(precision*nCores-1 downto 0) -- Output data
        );
end StatevectorMemory;

-- Defining the architecture of the entity
architecture Behavioral of StatevectorMemory is
    -- Defining a new type 'statevector' as an array of std_logic_vector
    type statevector is array(0 to 2**maxQubits-1) of std_logic_vector(precision-1 downto 0);
    -- Defining a signal 'memory' of type 'statevector' and initializing it in a way that all qubits are in the |0> state
    signal memory : statevector := (0 => "0100000000000000000000000000000000000000000000000000000000000000",
                                    others => (others => '0'));

begin
    -- Process to read and write data from and to the memory
    process(clk)
    begin
        if rising_edge(clk) then
            --reset memory
            if reset = '1' then
                memory <= (others => (others => '0'));
            end if;
            
            if write_en = '1' then
                for i in 0 to 3 loop
                    -- Update four consecutive elements in the memory
                    memory(to_integer(unsigned(address_write)) + i) <= data_in((i+1)*precision - 1 downto i*precision);
                end loop;

            end if;
            if read_en = '1' then
                for i in 0 to 3 loop
                    -- Read four consecutive elements from the memory
                    data_out((i+1)*precision - 1 downto i*precision) <= memory(to_integer(unsigned(address_read)) + i);
                end loop;
                    
            end if;
        end if;
    end process;

end Behavioral;