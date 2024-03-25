library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
 generic(
    NUM_CORES: natural:=2; --used to specify the number of Cores being used to do the processing. must be a power of 2
    PRECISION: natural:=64; --refers to the precision of the complex numbers being used. Cannot be greater than 128 and must be an even number as the bits are evenly shared between the real and imaginary part
    MAX_QUBITS: natural:=14; --determines the size of the statevector memory
    BAUD_RATE : natural:=460800 --baud rate used for serial communication
);
  port(
    system_clk: in std_logic; --clock
    reset_btn: in std_logic; --reset the current program
    tx: out std_logic; --data out
    rx: in std_logic; --data in
    seg: out std_logic_vector(6 downto 0); --seven segment leds
    an: out std_logic_vector(3 downto 0); --seven segment digits
    led : out std_logic_vector(15 downto 0)--overflow leds
    );
end top;

architecture Behavioral of top is

    --declare components
    
    component ClockGenerator
        port
         (-- Clock in ports
          -- Clock out ports
          clk_out_100          : out    std_logic;
          clk_out_200          : out    std_logic;
          -- Status and control signals
          reset             : in     std_logic;
          locked            : out    std_logic;
          clk_in           : in     std_logic
         );
     end component;
     
     component StatevectorMemory is
       Generic(
              precision : natural; -- Precision of the data
              MAX_QUBITS : natural; -- Maximum number of qubits
              NUM_CORES : natural -- Number of cores
              );
              
        Port (
              clk : in std_logic; -- Clock signal
              reset : in std_logic; -- Reset signal
              write_en : in std_logic; -- Write enable signal
              read_en : in std_logic; -- Read enable signal
    
              -- address_read and address_write point to the first element of the memory that needs to be read/updated
              address_read : in std_logic_vector(MAX_QUBITS-1 downto 0); -- Read address of the memory
              address_write : in std_logic_vector(MAX_QUBITS-1 downto 0); -- Write address of the memory
    
              data_in : in std_logic_vector(precision*NUM_CORES-1 downto 0); -- Input data
              data_out : out std_logic_vector(precision*NUM_CORES-1 downto 0) -- Output data
              );
    end component;
        
    component Timer is
        Port ( 
            clk : in std_logic;
            count_en : in std_logic;
            reset : in std_logic;
            seg: out std_logic_vector(6 downto 0); --led segments of 7 segment display
            an: out std_logic_vector(3 downto 0); -- determines which 7 segment display is turned on
            overflow: out std_logic_vector(15 downto 0) -- leds that signalize overflow of timer
            );
     end component;
          
    --signals (signals belonging to certain components are organized into groups, general multiused signals like clocks are also organized into groups)
    
    --clocks
    signal w_clk_100 : std_logic;
    signal w_clk_200 : std_logic;
    signal w_clk_rdy : std_logic;
    
    --reset
    signal w_main_reset : std_logic;
    
    --data
    
    --Timer
    signal w_timer_count_en : std_logic;
    
    --Statevector Memory
    signal w_StatevectorMemory_write_en : std_logic;
    signal w_StatevectorMemory_read_en : std_logic;
    signal w_StatevectorMemory_address_read : std_logic_vector(2**MAX_QUBITS-1 downto 0);
    signal w_StatevectorMemory_address_write : std_logic_vector(2**MAX_QUBITS-1 downto 0);
    signal w_StatevectorMemory_data_in : std_logic_vector(precision*NUM_CORES-1 downto 0);
    signal w_StatevectorMemory_data_out : std_logic_vector(precision*NUM_CORES-1 downto 0);
    
    
    

begin
   ClockGenerator_inst : ClockGenerator
       port map ( 
                clk_out_100 => w_clk_100,
                clk_out_200 => w_clk_200,              
                reset => w_main_reset,
                locked => w_clk_rdy,
                clk_in => system_clk
                );
    
    StatevectorMemory_inst : StatevectorMemory
        generic map(
                    precision => precision,
                    MAX_QUBITS => MAX_QUBITS,
                    NUM_CORES => NUM_CORES
                    )
        port map(
                clk => w_clk_200,
                reset => w_main_reset,
                write_en => w_StatevectorMemory_write_en,
                read_en => w_StatevectorMemory_read_en,
                address_read => w_StatevectorMemory_address_read,
                address_write => w_StatevectorMemory_address_write,
                data_in => w_StatevectorMemory_data_in,
                data_out => w_StatevectorMemory_data_out
                );
    
    Timer_inst : Timer
        port map(
                clk => w_clk_100,
                count_en => w_timer_count_en,
                reset => w_main_reset,
                seg => seg,
                an => an,
                overflow => led
                );
            
end Behavioral;
