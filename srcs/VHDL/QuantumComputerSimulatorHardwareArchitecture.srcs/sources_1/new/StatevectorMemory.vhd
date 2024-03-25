-- Importing the necessary libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL; -- Standard Logic Package
use IEEE.NUMERIC_STD.ALL; -- Numeric Standard Package

-- Defining the entity StatevectorMemory
entity StatevectorMemory is
  -- Generic parameters for the entity
  Generic(
          PRECISION : natural; -- Precision of the data
          MAX_QUBITS : natural; -- Maximum number of qubits
          NUM_CORES : natural -- Number of cores
          );
          
  -- Port declaration for the entity
    Port (clk : in std_logic; -- Clock signal
        reset : in std_logic; -- Reset signal
        write_en : in std_logic; -- Write enable signal
        read_en : in std_logic; -- Read enable signal

        -- address_read and address_write point to the first element of the memory that needs to be read/updated
        address_read : in std_logic_vector(MAX_QUBITS-1 downto 0); -- Read address of the memory
        address_write : in std_logic_vector(MAX_QUBITS-1 downto 0); -- Write address of the memory

        data_in : in std_logic_vector(PRECISION*NUM_CORES-1 downto 0); -- Input data
        data_out : out std_logic_vector(PRECISION*NUM_CORES-1 downto 0) -- Output data
        );
end StatevectorMemory;

-- Defining the architecture of the entity
architecture Behavioral of StatevectorMemory is
    --define a constant for the number one for initializing the memory
    constant C_ONE : std_logic_vector := "01000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"; 
    -- Defining a new type 'statevector' as an array of std_logic_vector
    type statevector is array(0 to 2**MAX_QUBITS-1) of std_logic_vector(PRECISION-1 downto 0);
    -- Defining a signal 'memory' of type 'statevector' and initializing it in a way that all qubits are in the |0> state
    signal memory : statevector := (0 => C_ONE(127 downto 128-PRECISION),
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
                    memory(to_integer(unsigned(address_write)) + i) <= data_in((i+1)*PRECISION - 1 downto i*PRECISION);
                end loop;

            end if;
            if read_en = '1' then
                for i in 0 to 3 loop
                    -- Read four consecutive elements from the memory
                    data_out((i+1)*PRECISION - 1 downto i*PRECISION) <= memory(to_integer(unsigned(address_read)) + i);
                end loop;
                    
            end if;
        end if;
    end process;

end Behavioral;