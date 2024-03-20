library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity ProcessingUnit is
  generic(
  precision: integer
  );
  
  Port ( 
   v_a_in: in std_logic_vector(precision-1 downto 0);
   v_b_in: in std_logic_vector(precision-1 downto 0);
   matrix_in: in std_logic_vector(11 downto 0);
   v_a_out : out std_logic_vector(precision-1 downto 0);
   v_b_out : out std_logic_vector(precision-1 downto 0);
   update_a_enable : in std_logic;
   update_b_enable : in std_logic
  );
end ProcessingUnit;

architecture Behavioral of ALU is
    signal matrix_0_0 : std_logic_vector(2 downto 0);
    signal matrix_0_1 : std_logic_vector(2 downto 0);
    signal matrix_1_0 : std_logic_vector(2 downto 0);
    signal matrix_1_1 : std_logic_vector(2 downto 0);
 
    procedure multiplyComplex(
                        x: in std_logic_vector(precision-1 downto 0);
                        kind: in std_logic_vector(2 downto 0);
                        result: out std_logic_vector(precision-1 downto 0)
                        )is
   variable real_x : signed(precision/2-1 downto 0);
   variable imag_x : signed(precision/2-1 downto 0);
   variable real_result : signed(precision/2-1 downto 0);
   variable imag_result : signed(precision/2-1 downto 0);
   
   variable temp_result: signed(precision-1 downto 0); --will hold result of multiplication as it needs to be twice as large as the factors
   
   variable std_temp_real: std_logic_vector(precision/2-1 downto 0);
   variable std_temp_imag: std_logic_vector(precision/2-1 downto 0);
   
   constant one_over_root_2 : signed(precision/2-1 downto 0) := "00101101010000010011110011001100"; -- constant value 1/2**0.5 --00101101010000010011110011001100 32 bit, 0010110101000001 16 bit, 00101101010000010011 20bit, 001011010100000100111100 24 bit
   constant negative_one_over_root_2: signed(precision/2-1 downto 0) := "11010010101111101100001100110011"; -- constant value -1/2**0.5 --10101101010000010011110011001100 32 bit, 1010110101000001 16 bit, 10101101010000010011 20bit, 101011010100000100111100 24 bit
   
   begin
       real_x := signed(x(precision-1 downto precision/2));
       imag_x := signed(x(precision/2-1 downto 0));
            
       if kind = "001" then --multiply by one
            real_result := real_x;
            imag_result := imag_x;
       
       elsif kind = "010" then --multiply by -1
            real_result := not real_x;
            imag_result := not imag_x;
       
       elsif kind = "011" then --multiply by 1/sqrt(2)
            temp_result := resize(real_x * one_over_root_2, temp_result'length);
            real_result := temp_result(precision-1) & temp_result(precision-4 downto precision/2-2);
            
            temp_result := resize(imag_x * one_over_root_2, temp_result'length);
            imag_result := temp_result(precision-1) & temp_result(precision-4 downto precision/2-2);

       elsif kind = "100" then --multiply by -1/sqrt(2)
            temp_result := resize(real_x * one_over_root_2, temp_result'length);
            real_result := temp_result(precision-1) & temp_result(precision-4 downto precision/2-2);
            real_result := not real_result;
            
            temp_result := resize(imag_x * one_over_root_2, temp_result'length);
            imag_result := temp_result(precision-1) & temp_result(precision-4 downto precision/2-2);
            imag_result := not imag_result;
            
              
       elsif kind = "101" then -- multiply by e^(i*pi/4)
            temp_result := resize(one_over_root_2 * (real_x - imag_x), temp_result'length);
            real_result := temp_result(precision-1) & temp_result(precision-4 downto precision/2-2);
            
            temp_result := resize(one_over_root_2 * (real_x + imag_x), temp_result'length);
            imag_result := temp_result(precision-1) & temp_result(precision-4 downto precision/2-2);
                  
       else -- multiply by 0
            real_result := (others => '0');
            imag_result := (others => '0');
       
       end if;
       
       std_temp_real := std_logic_vector(real_result);
       std_temp_imag := std_logic_vector(imag_result);
       
       result := std_temp_real & std_temp_imag;
       
   end procedure;
    
   procedure addComplex(
                          x : in std_logic_vector(precision-1 downto 0);
                          y : in std_logic_vector(precision-1 downto 0);
                          result : out std_logic_vector(precision-1 downto 0))is
                        
   variable real_x : signed(precision/2-1 downto 0);
   variable imag_x : signed(precision/2-1 downto 0);
   variable real_y : signed(precision/2-1 downto 0);
   variable imag_y : signed(precision/2-1 downto 0);
   
   variable real_result : std_logic_vector(precision/2-1 downto 0);
   variable imag_result : std_logic_vector(precision/2-1 downto 0);
   begin
        real_x := signed(x(precision-1 downto precision/2));
        imag_x := signed(x(precision/2-1 downto 0));
        
        real_y := signed(y(precision-1 downto precision/2));
        imag_y := signed(y(precision/2-1 downto 0));
        
        real_result := std_logic_vector(real_x + real_y);
        imag_result := std_logic_vector(imag_x + imag_y);
        
        result := real_result & imag_result;
     
   end procedure;
   
    
begin
    matrix_0_0 <= matrix_in(11 downto 9);
    matrix_0_1 <= matrix_in(8 downto 6);
    matrix_1_0 <= matrix_in(5 downto 3);
    matrix_1_1 <= matrix_in(2 downto 0);
    multiplyAccumulate : process (v_a_in, v_b_in, matrix_in, matrix_0_0,matrix_0_1, matrix_1_0, matrix_1_1)
    variable result_0_0 : std_logic_vector(precision-1 downto 0);
    variable result_0_1 : std_logic_vector(precision-1 downto 0);
    variable result_1_0 : std_logic_vector(precision-1 downto 0);
    variable result_1_1 : std_logic_vector(precision-1 downto 0);
    
    variable a_result : std_logic_vector(precision-1 downto 0);
    variable b_result : std_logic_vector(precision-1 downto 0);

    begin
        --update a
        if update_a_enable = '1' then
            multiplyComplex(v_a_in, matrix_0_0, result_0_0);
            multiplyComplex(v_b_in, matrix_0_1, result_0_1);
            addComplex(result_0_0, result_0_1, a_result);
        else
            a_result := v_a_in;
        end if;
        
        --update b
        if update_b_enable = '1' then
            multiplyComplex(v_a_in, matrix_1_0, result_1_0);
            multiplyComplex(v_b_in, matrix_1_1, result_1_1);
            addComplex(result_1_0, result_1_1, b_result);
        else
            b_result := v_b_in;
        end if;
        
        v_a_out <= a_result;
        v_b_out <= b_result;
        

    end process;
    
    
end Behavioral;

