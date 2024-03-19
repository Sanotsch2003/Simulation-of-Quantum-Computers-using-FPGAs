library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity coreCache is
 Generic(
            precision: integer:=64; 
            maxQubits: integer:=14
    );
 Port (
        clk: in std_logic;
        reset: in std_logic;
        address_in: in std_logic_vector(maxQubits-1 downto 0);
        write_address_en : in std_logic;
        read_address_en : in std_logic;
        data_in : in std_logic_vector(precision-1 downto 0);
        write_data_en : in std_logic;
        read_data_en : in std_logic;
        address_out: out std_logic_vector(maxQubits-1 downto 0):= (others => '0');
        data_out : out std_logic_vector(precision-1 downto 0):= (others => '0')
  );
end coreCache;

architecture Behavioral of coreCache is
    signal address_reg : std_logic_vector(maxQubits-1 downto 0) := (others => '0');
    signal data_reg : std_logic_vector(precision-1 downto 0) := (others => '0');
    
    
begin
    process(clk)
    begin
    if rising_edge(clk) then
        if (reset = '1') then
            address_reg <= (others => '0');
            data_reg <= (others => '0');
        
        else
            if (write_address_en = '1') then
                address_reg <= address_in;
             
            end if;
            
            if (write_data_en = '1') then
                data_reg <= data_in;
            end if;
            
            if (read_data_en = '1') then
                data_out <= data_reg;
            else
                data_out <= (others => '0');
            end if;   
            
            if (read_address_en = '1') then
                address_out <= address_reg;
            else
                address_out <= (others => '0');
            end if;
    
        end if;
    
    end if;
    
    end process;

end Behavioral;
