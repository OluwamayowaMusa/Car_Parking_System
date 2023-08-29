library ieee;
use ieee.std_logic_1164.all;

ENTITY int_to_four_bit IS
	PORT(number: IN INTEGER RANGE 0 TO 10;
		  four_bit: OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
		  );
END ENTITY int_to_four_bit;

ARCHITECTURE behaviour of int_to_four_bit IS
BEGIN
	WITH number SELECT 
		four_bit <= "0000" WHEN 0,
		            "0001" WHEN 1,
						"0010" WHEN 2,
						"0011" WHEN 3,
						"0100" WHEN 4,
						"0101" WHEN 5,
						"0110" WHEN 6,
						"0111" WHEN 7,
						"1000" WHEN 8,
						"1001" WHEN 9,
						"0000" WHEN OTHERS;
END ARCHITECTURE behaviour;