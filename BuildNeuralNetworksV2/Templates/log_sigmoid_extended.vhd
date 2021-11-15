-------------------------------------------------------------------------------
--*************************** log_sigmoid *************************************
-- This implementation is first introduced by Tomminska in year 2003.
-- The function of log_sigmoid has been minimized with the use of Software
-- 'Minilog Logic Minimizer'. There have been used 7 bits for the input, 3 to
-- represent the integer part, 4 to represent the fraction part and 7 bits to
-- represent the output. Therefore input is in the range of values [-8,8] and in 
-- case of negative values, the output is calculated with the form : 1 - y, 
-- because of the symmetric logsig function. Below are the equations that will
-- eventually be implemented in VHDL using exclusively logical gates.
-- y(6) = 1
-- y(5) = CD + CE + CF + A + B
-- y(4) = A + B + CD'E'F' + C'DE + C'DF + C'DG
-- y(3) = CD + A + B'C'EF + B'C'EG + B'DE'F'G' + CE'F' + BC + BDE
-- y(2) = A + B'C'DF'G' + CEFG + B'CEG + DE'FG + B'C'D'FG + CDE + B'C'EF'G'
--      + B'CD'E'F' + BC'D'EF + BC'D'EG + BDE' + B'CEF
-- y(1) = B'CEF + BCD'EF' + B'C'DG' + BC'E'F + A'B'C'FG' + BCD'FG' + BC'DE' + CD'E'G
--      + B'CDEG + D'EF'G' + B'DEF + B'DFG' + AB + AD + AE + AFG + AC
-- y(0) = AB + AC + AD'E'G' + BCDE + A'B'E'F'G + BC'DF + A'B'EFG + C'D'E'F'G
--      + A'B'C'D'E + A'B'C'D'F + BD'EG' + A'C'FG + A'B'C'DE' + CD'F'G' + CEF'G'
--      + ADEF + BCEF'
-------------------------------------------------------------------------------


library ieee;
library ieee_proposed;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee_proposed.fixed_pkg.all;
use work.neural_library.all;


entity log_sigmoid is

	PORT(
		input	: IN fixedX;
		enable  : IN STD_LOGIC;
		CLK     : IN STD_LOGIC;
		output  : OUT STD_LOGIC_VECTOR(7 downto 0)
	);
	
END entity log_sigmoid;

architecture log_sigmoid of log_sigmoid IS

	constant ONE          : ufixed(0 downto -7) := "10000000";
	
BEGIN
process(CLK) IS

  variable y              : STD_LOGIC_VECTOR(7 downto 0);
  variable x              : STD_LOGIC_VECTOR(6 downto 0);
  variable minus_input    : sfixed(UPPER_LIMIT+1 downto DOWN_LIMIT);
  variable pre_output     : ufixed(0 downto -7);
  variable mid            : ufixed(0  downto -7);
  variable temp1          : STD_LOGIC;
  variable temp2          : STD_LOGIC;
  variable smaller_than_8 : STD_LOGIC;
  variable greater_than_8 : STD_LOGIC;
  variable p              : STD_LOGIC_VECTOR(56 downto 1);

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
		
	  IF (smaller_than_8 = '0' AND input(UPPER_LIMIT) = '1') THEN      -- This first condition checks if input < -8, and if so, sets output to 0.
	    output <= "00000000";
	  ELSIF (greater_than_8 = '1' AND input(UPPER_LIMIT) = '0') THEN   -- This condition checks if input > 8, and if so, sets output to 1.
	    output <= "10000000";
	  ELSE
	    IF (input(UPPER_LIMIT) = '0') THEN                             -- If input is in the range [0,8] then we use variable x to store
		    FOR i IN 6 downto 0 LOOP                                   -- 7 bits, that are needed for the implementation.
			  x(i) := input(i-4);
			END LOOP;
		ELSIF (input(UPPER_LIMIT) = '1') THEN                          -- Otherwise, if input is in the range [-8,0] we calculate the opposite 
			minus_input := - input;                                    -- input, and store the bits in variable x.
		    FOR i IN 6 downto 0 LOOP
			  x(i) := minus_input(i-4);
			END LOOP;
		END IF;
			p(1) := x(4) AND x(3);
			p(2) := x(4) AND x(2);
			p(3) := x(4) AND x(1);
			p(4) := x(4) AND NOT x(3) AND NOT x(2) AND NOT x(1);
			p(5) := x(3) AND x(2) AND NOT x(4);
			p(6) := x(3) AND x(1) AND NOT x(4);
			p(7) := x(3) AND x(0) AND NOT x(4);
			p(8) := x(2) AND x(1) AND NOT x(5) AND NOT x(4);
			p(9) := x(2) AND x(0) AND NOT x(5) AND NOT x(4);
			p(10) := x(3) AND NOT x(5) AND NOT x(2) AND NOT x(1) AND NOT x(0);
			p(11) := x(4) AND NOT x(2) AND NOT x(1);
			p(12) := x(5) AND x(4);
			p(13) := x(5) AND x(3) AND x(2);
			p(14) := x(3) AND NOT x(5) AND NOT x(4) AND NOT x(1) AND NOT x(0);
			p(15) := x(4) AND x(2) AND x(1) AND x(0);
			p(16) := x(4) AND x(2) AND x(0) AND NOT x(5);
			p(17) := x(3) AND x(1) AND x(0) AND NOT x(2);
			p(18) := x(1) AND x(0) AND NOT x(5) AND NOT x(4) AND NOT x(3);
			p(19) := x(4) AND x(3) AND x(2);
			p(20) := x(2) AND NOT x(5) AND NOT x(4) AND NOT x(1) AND NOT x(0);
			p(21) := x(4) AND NOT x(5) AND NOT x(3) AND NOT x(2) AND NOT x(1);
			p(22) := x(5) AND x(2) AND x(1) AND NOT x(4) AND NOT x(3);
			p(23) := x(5) AND x(2) AND x(0) AND NOT x(4) AND NOT x(3);
			p(24) := x(5) AND x(3) AND NOT x(2);
			p(25) := x(4) AND x(2) AND x(1) AND NOT x(5);
			p(26) := x(5) AND x(4) AND x(2) AND NOT x(3) AND NOT x(1);
			p(27) := x(3) AND NOT x(5) AND NOT x(4) AND NOT x(0);
			p(28) := x(5) AND x(1) AND NOT x(4) AND NOT x(2);
			p(29) := x(1) AND NOT x(6) AND NOT x(5) AND NOT x(4) AND NOT x(0);
			p(30) := x(5) AND x(4) AND x(1) AND NOT x(3) AND NOT x(0);
			p(31) := x(5) AND x(3) AND NOT x(4) AND NOT x(2);
			p(32) := x(4) AND x(0) AND NOT x(3) AND NOT x(2);
			p(33) := x(4) AND x(3) AND x(2) AND x(0) AND NOT x(5);
			p(34) := x(2) AND NOT x(3) AND NOT x(1) AND NOT x(0);
			p(35) := x(3) AND x(2) AND x(1) AND NOT x(5);
			p(36) := x(3) AND x(1) AND NOT x(5) AND NOT x(0);
			p(37) := x(6) AND x(5);
			p(38) := x(6) AND x(3);
			p(39) := x(6) AND x(2);
			p(40) := x(6) AND x(1) AND x(0);
			p(41) := x(6) AND x(4);
			p(42) := x(6) AND NOT x(3) AND NOT x(2) AND NOT x(0);
			p(43) := x(5) AND x(4) AND x(3) AND x(2);
			p(44) := x(0) AND NOT x(6) AND NOT x(5) AND NOT x(2) AND NOT x(1);
			p(45) := x(5) AND x(3) AND x(1) AND NOT x(4);
			p(46) := x(2) AND x(1) AND x(0) AND NOT x(6) AND NOT x(5);
			p(47) := x(0) AND NOT x(4) AND NOT x(3) AND NOT x(2) AND NOT x(1);
			p(48) := x(2) AND NOT x(6) AND NOT x(5) AND NOT x(4) AND NOT x(3);
			p(49) := x(0) AND NOT x(6) AND NOT x(5) AND NOT x(4) AND NOT x(3);
			p(50) := x(5) AND x(2) AND NOT x(3) AND NOT x(0);
			p(51) := x(1) AND x(0) AND NOT x(6) AND NOT x(4);
			p(52) := x(3) AND NOT x(6) AND NOT x(5) AND NOT x(4) AND NOT x(2);
			p(53) := x(4) AND NOT x(3) AND NOT x(1) AND NOT x(0);
			p(54) := x(4) AND x(2) AND NOT x(1) AND NOT x(0);
			p(55) := x(6) AND x(3) AND x(2) AND x(1);
			p(56) := x(5) AND x(4) AND x(2) AND NOT x(0);
			
			y(7) := '0';
			y(6) := '1';
			y(5) := x(6) OR x(5) OR p(1) OR p(2) OR p(3);
			y(4) := x(6) OR x(5) OR p(4) OR p(5) OR p(6) OR p(7);
			y(3) := x(6) OR p(1) OR p(8) OR p(9) OR p(10) OR p(11) OR p(12) OR p(13);
			y(2) := x(6) OR p(14) OR p(15) OR p(16) OR p(17) OR p(18) OR p(19) OR p(20) OR p(21) OR p(22) OR p(23) OR p(24) OR p(25);
			y(1) := p(25) OR p(26) OR p(27) OR p(28) OR p(29) OR p(30) OR p(31) OR p(32) OR p(33) OR p(34) OR p(35) OR p(36) OR p(37) OR p(38) OR p(39) OR p(40) OR p(41);
			y(0) := p(37) OR p(41) OR p(42) OR p(43) OR p(44) OR p(45) OR p(46) OR p(47) OR p(48) OR p(49) OR p(50) OR p(51) OR p(52) OR p(53) OR p(54) OR p(55) OR p(56);
			pre_output :=  to_ufixed(y,0,-7);             -- Conversion from STD_LOGIC_VECTOR type to ufixed type
			CASE input(UPPER_LIMIT) IS
		      WHEN '0' =>                                 -- With positive input, output is as it comes from the second stage of logic gates.
				output <=  y;
			  WHEN '1' =>                                 -- With negative input, output is 1 - pre_output
				mid := resize(ONE - pre_output,0,-7);
				output <= to_slv(mid);
			  WHEN OTHERS => null;
         END CASE;
	  END IF;
    END IF;
  END IF;
END process;


END ARCHITECTURE log_sigmoid;