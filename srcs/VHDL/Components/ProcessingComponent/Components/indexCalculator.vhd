library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;



entity getVaAndVb is
    generic(
        maxQubits: integer
    );
    Port (
        n : in unsigned(maxQubits-1 downto 0);
        target : in unsigned(3 downto 0);
        a_out : out std_logic_vector(maxQubits-1 downto 0);
        b_out : out std_logic_vector(maxQubits-1 downto 0);
        
        update_a_enable : out std_logic := '1';
        update_b_enable : out std_logic := '1';
        control_qubit : in unsigned(3 downto 0);
        apply_control_gate : in std_logic
    );
end getVaAndVb;

architecture Behavioral of getVaAndVb is
    signal w_n: unsigned(15 downto 0);
begin

    process(n, target, w_n, control_qubit, apply_control_gate)
        variable mask, not_mask : unsigned(15 downto 0);
        variable n_and_mask, n_and_not_mask, one_mask, result_zero, result_one: unsigned(15 downto 0);  
    begin 

       for i in maxQubits to 15 loop
            w_n(i) <= '0';
       end loop;
       w_n(maxQubits-1 downto 0) <= n;
    
        mask := (others => '0');
        not_mask := (others => '1');

        for i in 0 to 15 loop
            if i<target then
                mask(i) := '1'; 
                not_mask(i) := '0';      
            end if;
        end loop;
        
        
        n_and_mask := w_n and mask;
        n_and_not_mask := w_n and not_mask;
        
        for i in 15 downto 1 loop
            n_and_not_mask(i) := n_and_not_mask(i-1);
        end loop;
            
        n_and_not_mask(0) := '0';
        
        result_zero := n_and_mask or n_and_not_mask;
        
        one_mask := (others => '0');
        for i in 0 to 15 loop
            if i=target then
            one_mask(i) := '1';
            end if;
        end loop;
        
        result_one := result_zero or one_mask;
        
        
        a_out <= std_logic_vector(result_zero(maxQubits-1 downto 0));
        b_out <= std_logic_vector(result_one(maxQubits-1 downto 0));

        --check which values to update (part of algorithm for applying controlled gates). The control qubit is cth in register. Only update a/b if cth bit in a/b is 1. 
        if apply_control_gate = '1' then
            update_a_enable <= result_zero(maxQubits-1 downto 0)(to_integer(control_qubit));
            update_b_enable <= result_one(maxQubits-1 downto 0)(to_integer(control_qubit));   
              
        --control gate is not applied, but values are always updated
        else
            update_a_enable <= '1';
            update_b_enable <= '1';    
        end if;      

    end process;
end Behavioral;

 