library ieee;
library ieee_proposed;
use ieee.std_logic_1164.all;
use ieee_proposed.fixed_pkg.all;
use work.neural_library.all;
use work.output_LUTS.all;

ENTITY ann IS
	GENERIC (                                                     -- These generic values stand for:
      N_I : INTEGER := N_INPUTS;                                      -- N_I : Number of Inputs
      N_H : INTEGER := N_HIDDEN;                                      -- N_H : Number of Hidden Nodes
      N_O : INTEGER := N_OUTPUTS                                      -- N_O : Number of Output Nodes
	);                                                            -- and regulate the size of the circuit
	
	PORT (
      input           : IN  ann_input_vector ; 
      ann_mode        : IN  ann_modes;
      CLK             : IN  STD_LOGIC;
      Enable          : IN  STD_LOGIC :='0';
      Ready           : OUT STD_LOGIC :='1';
      output          : OUT STD_LOGIC_VECTOR(1 to N_OUTPUTS)
	);
END ENTITY ann;

ARCHITECTURE ann OF ann IS

	signal ann_state          : ann_modes := idle;
	signal hidden_layer_en    : STD_LOGIC_VECTOR(N_H-1 downto 0) := (others =>'0');
	signal output_layer_en    : STD_LOGIC_VECTOR(N_O-1 downto 0) := (others =>'0');
	signal hidden_layer_mode  : node_modes;
	signal output_layer_mode  : node_modes;
	signal hidden_output      : hidden_vector;
	signal hidden_layer_flag  : STD_LOGIC;
	signal hidden_node_flag   : STD_LOGIC_VECTOR(N_H-1 downto 0);
	signal output_layer_flag  : STD_LOGIC;
	signal output_node_flag   : STD_LOGIC_VECTOR(N_O-1 downto 0);
	
BEGIN
	
	-- Create a specific number of hidden nodes and instantiate them

    hidden_layer : FOR i IN 1 to N_H GENERATE               
        hidden_nodes : hidden_node generic map( N_I,
                                                i
                                   )
                                   port    map(
                                               input,
                                               hidden_layer_en(i-1),
                                               hidden_layer_mode,
                                               CLK,
                                               hidden_node_flag(i-1),
                                               hidden_output(i)
                                   );
    END GENERATE hidden_layer;
	
	
	
	-- Create a specific number of output nodes and instantiate them
	
    output_layer : FOR i IN 1 to N_O GENERATE             
        output_nodes : output_node generic map( N_H,
                                                i
                                   )
                                   port    map(
                                               hidden_output,
                                               output_layer_en(i-1),
                                               output_layer_mode,
                                               CLK,
                                               output_node_flag(i-1),
                                               output(i)
                                   );
    END GENERATE output_layer;
	
-----------------------------------------------------------------
-- This process controls the function of the neural network.
-- It may trigger the nodes of one particular layer or enable
-- one node at a time, in order to load them with its values,
-- weights and biases.
-- When processing is done in the nodes, the FSM waits for 
-- the results, in order to move to the next state. This is 
-- ensured with the IF conditions previous to the FSM description
-----------------------------------------------------------------

	
fsm: process(CLK) IS
BEGIN
  IF (CLK = '1' AND CLK'EVENT) THEN
    IF (Enable = '1') THEN
	   IF (hidden_layer_mode /= idle OR output_layer_mode /= idle) THEN
		  hidden_layer_mode <= idle;
		  output_layer_mode <= idle;
        ELSIF (hidden_layer_flag = '1' AND output_layer_flag = '1') THEN
            CASE ann_state is                                   -- Description of the FSM, possible states
                WHEN run =>                             		    -- Enables all of hidden nodes and sends a signal to start processing
                  hidden_layer_mode <= run;					
                  hidden_layer_en <= (others => '1');
                  ann_state <= run_next;
                WHEN run_next =>                                -- Disables all of hidden nodes, enables output nodes and sends signal to make processions
                  hidden_layer_en <= (others => '0'); 
                  output_layer_mode <= run;
                  output_layer_en <= (others => '1');
                  ann_state <= turn_off_output;
                WHEN turn_off_output =>                         -- Disables all of output nodes and sets the FSM in idle mode, until the next trigger.
                  output_layer_en <= (others =>'0');
                  Ready     <= '1';
                  ann_state <= idle;
                WHEN idle =>                                    -- When the FSM is set in idle mode, an outside trigger will change 
                  CASE ann_mode IS                              -- its state, and make things happen.
                    WHEN run =>                                 
                      ann_state <= run;
                      Ready     <= '0';
                    WHEN others =>
                      ann_state <= idle;
                      Ready     <= '1';
                  END CASE;
            END CASE;  
        END IF;
    END IF;	 
  END IF; 
END PROCESS;

-----------------------------------------------
-- This process acts as an AND gate, with its 
-- inputs being the flags of the hidden neurons,
-- which declare readiness with the value '1'
-----------------------------------------------

and_gate1: PROCESS(hidden_node_flag) IS

variable temp : STD_LOGIC;

BEGIN
  temp := '1';
  FOR i IN hidden_node_flag'range LOOP
    temp := temp AND hidden_node_flag(i);
  END LOOP;
  hidden_layer_flag <= temp;
  
END PROCESS;

-----------------------------------------------
-- This process acts as an AND gate, with its 
-- inputs being the flags of the output neurons,
-- which declare readiness with the value '1'
-----------------------------------------------

and_gate2: PROCESS(output_node_flag) IS

variable temp : STD_LOGIC;

BEGIN
  temp := '1';
  FOR i IN output_node_flag'range LOOP
    temp := temp AND output_node_flag(i);
  END LOOP;
  output_layer_flag <= temp;

END PROCESS;

END ARCHITECTURE ann;
