-------------------------------------------------------------------------------
--*************************** log_sigmoid *************************************
-- This implementation is first introduced by Tomminska in year 2003.
-- The function of log_sigmoid has been minimized with the use of Software
-- 'Minilog Logic Minimizer'. There have been used 7 bits for the input, 3 to
-- represent the integer part, 4 to represent the fraction part and 7 bits to
-- represent the output. Therefore input is in the range of values [-8,8] and in 
-- case of negative values, the output is calculated with the form : 1 - y, 
-- because of the symmetric logsig function.
------------------------------------------------------------------------------

library ieee;
library ieee_proposed;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee_proposed.fixed_pkg.all;
use work.neural_library.all;


ENTITY log_sigmoid IS

	PORT(
		input	: IN fixedX;
		enable  : IN STD_LOGIC;
		CLK     : IN STD_LOGIC;
		output  : OUT STD_LOGIC_VECTOR(7 downto 0)
	);
	
END ENTITY log_sigmoid;

ARCHITECTURE log_sigmoid OF log_sigmoid IS

	constant ONE          : ufixed(0 downto -7) := "10000000";
	
BEGIN

PROCESS(CLK) IS

  variable y              : STD_LOGIC_VECTOR(7 downto 0);
  variable x              : STD_LOGIC_VECTOR(5 downto 0);
  variable minus_input    : sfixed(UPPER_LIMIT+1 downto DOWN_LIMIT);
  variable pre_output     : ufixed(0 downto -7);
  variable mid            : ufixed(0  downto -7);
  variable temp1          : STD_LOGIC;
  variable temp2          : STD_LOGIC;
  variable smaller_than_8 : STD_LOGIC;
  variable greater_than_8 : STD_LOGIC;
  variable p              : STD_LOGIC_VECTOR(27 downto 1);

BEGIN
  IF (CLK'event) AND (CLK = '1') THEN
    IF (enable = '1') THEN 
	   temp1 := '1';
	   temp2 := '0';
	   FOR i IN 3 to UPPER_LIMIT LOOP
	     temp1 := temp1 AND input(i);
	     temp2 := temp2 OR input(i);
	   END LOOP;
	
	   smaller_than_8 := temp1;
	   greater_than_8 := temp2;
		
	  IF (smaller_than_8 = '0' AND input(UPPER_LIMIT) = '1') THEN
	    output <= "00000000";
	  ELSIF (greater_than_8 = '1' AND input(UPPER_LIMIT) = '0') THEN
	    output <= "10000000";
	  ELSE
	    IF (input(UPPER_LIMIT) = '0') THEN
		   FOR i IN 5 downto 0 LOOP
			  x(i) := input(i-3);
			END LOOP;
		 ELSIF (input(UPPER_LIMIT) = '1') THEN
			minus_input := - input;
		   FOR i IN 5 downto 0 LOOP
			  x(i) := minus_input(i-3);
			END LOOP;
		 END IF;

	  p(1) := x(2) AND x(5);
	  p(2) := x(4) AND x(5);
	  p(3) := '1' AND x(5);
	  p(4) := x(3) AND x(5);
	  p(5) := NOT x(0) AND NOT x(1) AND NOT x(2) AND NOT x(3) AND x(4);
	  p(6) := NOT x(0) AND NOT x(1) AND NOT x(2) AND x(3) AND NOT x(4);
	  p(7) := NOT x(0) AND x(1) AND x(2) AND NOT x(3) AND NOT x(4);
	  p(8) := NOT x(0) AND x(1) AND NOT x(2) AND x(3);
	  p(9) := x(0) AND x(1) AND x(2) AND x(3);
	  p(10) := x(0) AND x(1) AND NOT x(3) AND x(4);
	  p(11) := x(1) AND x(2) AND x(4);
	  p(12) := x(0) AND x(1) AND x(3) AND NOT x(4);
	  p(13) := x(1) AND x(2) AND x(3);
	  p(14) := x(0) AND NOT x(1) AND x(3);
	  p(15) := x(0) AND x(2) AND x(4);
	  p(16) := x(1) AND NOT x(2) AND NOT x(3) AND x(4);
	  p(17) := x(1) AND NOT x(2) AND NOT x(3) AND NOT x(4);
	  p(18) := x(2) AND x(3) AND NOT x(4);
	  p(19) := x(2) AND x(3) AND x(4);
	  p(20) := x(2) AND NOT x(3);
	  p(21) := x(0) AND x(1) AND x(2) AND NOT x(4);
	  p(22) := x(0) AND NOT x(1) AND x(2) AND NOT x(4);
	  p(23) := NOT x(1) AND x(2) AND NOT x(3) AND x(4);
	  p(24) := x(0) AND NOT x(1) AND NOT x(2) AND x(4);
	  p(25) := x(0) AND NOT x(2) AND NOT x(3) AND NOT x(4);
	  p(26) := x(3) AND x(4);
	  p(27) := NOT x(0) AND NOT x(2) AND x(3) AND x(4);
	  
	  
	  y(7) := '0';
	  y(6) := '1';
	  y(5) := p(3) OR p(5) OR p(8) OR p(10) OR p(11) OR p(12) OR p(13) OR p(14) OR p(15) OR p(16) OR p(18) OR p(23) OR p(24) OR p(26);
	  y(4) := p(3) OR p(5) OR p(6) OR p(10) OR p(11) OR p(15) OR p(16) OR p(20) OR p(24) OR p(26);
	  y(3) := p(3) OR p(6) OR p(11) OR p(13) OR p(17) OR p(18) OR p(21) OR p(26);
	  y(2) := p(3) OR p(6) OR p(7) OR p(9) OR p(12) OR p(13) OR p(16) OR p(19) OR p(23) OR p(25);
	  y(1) := p(3) OR p(6) OR p(7) OR p(8) OR p(12) OR p(21) OR p(22) OR p(23) OR p(24) OR p(27);
	  y(0) := p(1) OR p(2) OR p(4) OR p(5) OR p(7) OR p(8) OR p(10) OR p(13) OR p(14) OR p(15) OR p(18) OR p(22);
	  pre_output :=  to_ufixed(y,0,-7);
			CASE input(UPPER_LIMIT) IS
		      WHEN '0' => 
				 output <=  y;
			  WHEN '1' =>
				 mid := resize(ONE - pre_output,0,-7);
				 output <= to_slv(mid);
			  WHEN OTHERS => null;
            END CASE;
		END IF;
    END IF;
  END IF; 
end process;

END architecture log_sigmoid;		