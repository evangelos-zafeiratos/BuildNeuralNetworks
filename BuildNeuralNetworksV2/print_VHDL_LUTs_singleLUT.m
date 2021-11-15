function [] = print_VHDL_LUTs_singleLUT(neural, normalized_list, binary_list, compressed_list, ...
                          N_ROWS, accuracy, RTS_bits, compressed_RTS_bits, ~, ~, ...
                          trigger_CLK, switch_criteria, switch_enable, No_train_enable, index)
                      
% This funcion creates files containing VHDL code that form a Neural
% Network initially, and after the Simulation, a hybrid Network. The
% particular architecture invokes the use of LUTS instead of multipliers 
% in the target Hardware.

% Store the current folder as a string                      
CurrentFolder = pwd; 

% Decides whether the circuits use Positive or Negative Edge CLK to trigger
% their Flip - Flops
CLK_STATE = trigger_CLK;

% Extract the quantitive attributes that define our newly created Neural
% Network 
N_INPUTS  = size(neural.IW{1},2);    
N_HIDDEN  = size(neural.b{1},1);
N_OUTPUTS = size(neural.b{2},1);
N_SCENARIOS = size(switch_criteria,1);

% These arrays holding the values of hidden and output weights will be used
% later for the multiplications.
hidden_weights = neural.iw{1}';
output_weights = neural.lw{2}';

% Create the structures that are going to hold the values of multiplier LUT
HIDDEN_LUT = cell(N_HIDDEN,N_INPUTS);
OUTPUT_LUT = cell(N_OUTPUTS,N_HIDDEN);

% This structure will hold 129 discrete values in range [0,1] with step:2^-7
hidden_output = cell(129,1);

% Create identifiers for all VHDL files to be printed.
fid  = fopen('hidden_LUTS.vhd','w');
fid2 = fopen('output_LUTS.vhd','w');
fid3 = fopen('neural_library.vhd','w');
fid4 = fopen('hidden_node.vhd','w');
fid5 = fopen('output_node.vhd','w');
fid6 = fopen('pre_hybrid.vhd','w');
fid7 = fopen('testbench.vhd','w');
fid8 = fopen('pre_hybrid_part1.vhd','w');
fid9 = fopen('pre_hybrid_part2.vhd','w');
fid10= fopen('testbench_final.vhd','w');

input_map = {'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven', 'twelve'};

% Calculation of how many stages for tree adders is going to be used.
adder_tree1 = ceil(log2(N_INPUTS+1));
adder_tree2 = ceil(log2(N_HIDDEN+1));



% Search among all weights and biases the value that is going to need the
% most bits to be represented.

max = 1;
for i = 1:length(hidden_weights)
    if abs(hidden_weights(i)) > max
        max = hidden_weights(i);
    end;
end;
for i = 1:length(output_weights)
    if abs(output_weights(i)) > max
        max = output_weights(i);
    end;
end;
for i = 1:length(neural.b{1})
    if abs(neural.b{1}(i)) > max
        max = neural.b{1}(i);
    end;
end;
for i = 1:length(neural.b{2})
    if abs(neural.b{2}(i)) > max
        max = neural.b{2}(i);
    end;
end;
 

% Use specific number of bits to represent the integer and fraction part
integer_bits  = real(ceil(log2(round(max))) + 2 + accuracy);
fraction_bits = real(int16(7 + accuracy));

% Calculate the values of weight*input for specific weights and for every
% possible weight, in regard to hidden nodes.
for i = 1:N_HIDDEN
    for j = 1:N_INPUTS
        for k = 1:size(normalized_list{j},1)
            size(normalized_list{j},1);
            normalized_list{j}(k);
            HIDDEN_LUT{i,j}(k) = hidden_weights((i-1)*N_INPUTS+j) * normalized_list{j}(k);
        end;
    end;
end;

% Instantiate the array with the binary representation of wanted values
l=0;
for k = 0:2^-7:1
    l = l+1;
    temp3 = sfi(k,8,7);
    hidden_output{l} = temp3.bin;
end;
hidden_output{129} = '10000000';

% Calculate the values of weight*input for specific weights and for every
% possible weight, in regard to output nodes.
for i = 1:N_OUTPUTS
    for j = 1:N_HIDDEN
        l=0;
        for k = 0:2^-7:1
            l = l+1;
            OUTPUT_LUT{i,j}(l) = output_weights((i-1)*N_HIDDEN+j) * k;
        end;
    end;
end;
           
            
 % Print VHDL code for the multiplication LUTS of hidden nodes
 fprintf(fid,'-------------------------------------------------\n');
 fprintf(fid,'-- This module substitutes multipliers when\n');
 fprintf(fid,'-- the dataset is such that allows it to happen.\n');
 fprintf(fid,'-- It consists of different entities, one per each\n');
 fprintf(fid,'-- hidden neuron.\n');
 fprintf(fid,'-------------------------------------------------\n');
 fprintf(fid,'LIBRARY ieee;\n');
 fprintf(fid,'LIBRARY ieee_proposed;\n');
 fprintf(fid,'USE ieee.std_logic_1164.all;\n');
 fprintf(fid,'use ieee_proposed.fixed_pkg.all;\n');
 fprintf(fid,'use work.neural_library.all;\n\n');
 fprintf(fid,'package hidden_LUTS IS\n\n');
 
 for i = 1:N_HIDDEN
     fprintf(fid,'COMPONENT hiddenNode_%d IS\n',i);
     fprintf(fid,'  PORT (\n');
     fprintf(fid,'        CLK             : IN  STD_LOGIC;\n');
     fprintf(fid,'        input           : IN  ann_input_vector;\n');
     fprintf(fid,'        Enable          : IN  STD_LOGIC;\n');
     fprintf(fid,'        Lut_output      : OUT fixedX_vector(1 to %d)\n',N_INPUTS);
     fprintf(fid,'  );\n');
     fprintf(fid,'END component;\n\n');
  end;
     fprintf(fid,'END package;\n\n');
 for j = 1:N_HIDDEN
     fprintf(fid,'LIBRARY ieee;\n');
     fprintf(fid,'LIBRARY ieee_proposed;\n');
     fprintf(fid,'USE ieee.std_logic_1164.all;\n');
     fprintf(fid,'use ieee_proposed.fixed_pkg.all;\n');
     fprintf(fid,'use work.neural_library.all;\n\n');
     fprintf(fid,'ENTITY hiddenNode_%d IS\n',j);
     fprintf(fid,'  PORT (\n');
     fprintf(fid,'        CLK             : IN  STD_LOGIC;\n');
     fprintf(fid,'        input           : IN  ann_input_vector;\n');
     fprintf(fid,'        Enable          : IN  STD_LOGIC;\n');
     fprintf(fid,'        Lut_output      : OUT fixedX_vector(1 to %d)\n',N_INPUTS);
     fprintf(fid,'  );\n');
     fprintf(fid,'END ENTITY;\n\n');
     fprintf(fid,'ARCHITECTURE hiddenNode_%d OF hiddenNode_%d IS\n',j,j);
     fprintf(fid,'BEGIN\n');
     fprintf(fid,'  PROCESS(CLK) IS\n');
     fprintf(fid,'    BEGIN\n');
     fprintf(fid,'      IF (CLK''EVENT AND CLK = ''%d'') THEN\n',CLK_STATE);
     fprintf(fid,'        IF (Enable = ''1'') THEN \n');
     for k = 1:N_INPUTS                                                     % Print LUT for every single weight, in total N_INPUTS*N_HIDDEN
         fprintf(fid,'        CASE input.%s IS\n',input_map{k});
         for l = 1:size(normalized_list{k},1)                                    
            temp  = sfi(HIDDEN_LUT{j,k}(l),integer_bits + fraction_bits ,fraction_bits);  % Convert from double to binary
            number = temp.bin;
            fprintf(fid,'          WHEN "%s"  => Lut_output(%d) <= "%s"; --   %f * %f = %f\n',compressed_list{k,l},k,number,  hidden_weights((j-1)*N_INPUTS+k),normalized_list{k}(l), HIDDEN_LUT{j,k}(l));
         end;
         fprintf(fid,'          WHEN OTHERS  => NULL;\n');
         fprintf(fid,'        END CASE;\n');
     end;
     fprintf(fid,'        END IF;\n');
     fprintf(fid,'      END IF;\n');
     fprintf(fid,'END PROCESS;\n');
     fprintf(fid,'END ARCHITECTURE;\n\n\n');
 end;
 fclose(fid);
 clear HIDDEN_LUT;  % Release from memory
 
 % Print VHDL code for the multiplication LUTS of output nodes
 fprintf(fid2,'-------------------------------------------------\n');
 fprintf(fid2,'-- This module replaces multipliers with LUTs of 129 \n');
 fprintf(fid2,'-- positions, as many as the possible outcomes of\n');
 fprintf(fid2,'-- log_sigmoid function. It offers significant impovement\n');
 fprintf(fid2,'-- in terms of area and frequency and it consists of\n');
 fprintf(fid2,'-- different entities, one per each output neuron.\n');
 fprintf(fid2,'-------------------------------------------------\n\n');
 fprintf(fid2,'LIBRARY ieee;\n');
 fprintf(fid2,'LIBRARY ieee_proposed;\n');
 fprintf(fid2,'USE ieee.std_logic_1164.all;\n');
 fprintf(fid2,'use ieee_proposed.fixed_pkg.all;\n');
 fprintf(fid2,'use work.neural_library.all;\n\n');
 fprintf(fid2,'package output_LUTS IS\n\n');
 
 for i = 1:N_OUTPUTS
     fprintf(fid2,'COMPONENT outputNode_%d IS\n',i);
     fprintf(fid2,'  PORT (\n');
     fprintf(fid2,'        CLK             : IN  STD_LOGIC;\n');
     fprintf(fid2,'        input           : IN  hidden_vector;\n');
     fprintf(fid2,'        Enable          : IN  STD_LOGIC;\n');
     fprintf(fid2,'        Lut_output      : OUT fixedX_vector(1 to %d)\n',N_HIDDEN);
     fprintf(fid2,'  );\n');
     fprintf(fid2,'END component;\n\n');
  end;
     fprintf(fid2,'END package;\n\n');
 for j = 1:N_OUTPUTS
     fprintf(fid2,'LIBRARY ieee;\n');
     fprintf(fid2,'LIBRARY ieee_proposed;\n');
     fprintf(fid2,'USE ieee.std_logic_1164.all;\n');
     fprintf(fid2,'use ieee_proposed.fixed_pkg.all;\n');
     fprintf(fid2,'use work.neural_library.all;\n\n');
     fprintf(fid2,'ENTITY outputNode_%d IS\n',j);
     fprintf(fid2,'  PORT (\n');
     fprintf(fid2,'        CLK             : IN  STD_LOGIC;\n');
     fprintf(fid2,'        input           : IN  hidden_vector;\n');
     fprintf(fid2,'        Enable          : IN  STD_LOGIC;\n');
     fprintf(fid2,'        Lut_output      : OUT fixedX_vector(1 to %d)\n',N_HIDDEN);
     fprintf(fid2,'  );\n');
     fprintf(fid2,'END ENTITY;\n\n');
     fprintf(fid2,'ARCHITECTURE outputNode_%d OF outputNode_%d IS\n',j,j);
     fprintf(fid2,'BEGIN\n');
     fprintf(fid2,'  PROCESS(CLK) IS\n');
     fprintf(fid2,'    BEGIN\n');
     fprintf(fid2,'      IF (CLK''EVENT AND CLK = ''%d'') THEN\n',CLK_STATE);
     fprintf(fid2,'        IF (Enable = ''1'') THEN \n');
     for k = 1:N_HIDDEN                                                     % Print LUT for every single weight, in total N_HIDDEN*N_OUTPUTS
         fprintf(fid2,'        CASE input(%d) IS\n',k);
         for l = 1:129
            temp = sfi(OUTPUT_LUT{j,k}(l),integer_bits + fraction_bits ,fraction_bits);  % Convert from double to binary
            number = temp.bin;
            fprintf(fid2,'          WHEN "%s"  => Lut_output(%d) <= "%s";  --   %f * %f = %f\n',hidden_output{l},k,number,output_weights((j-1)*N_HIDDEN+k),(l-1)*2^-7,OUTPUT_LUT{j,k}(l) );
         end;
         fprintf(fid2,'          WHEN OTHERS  => NULL;\n');
         fprintf(fid2,'        END CASE;\n');
     end;
     fprintf(fid2,'        END IF;\n');
     fprintf(fid2,'      END IF;\n');
     fprintf(fid2,'END PROCESS;\n');
     fprintf(fid2,'END ARCHITECTURE;\n\n\n');
 end;
 fclose(fid2);   
 clear OUTPUT_LUT;  % Release from memory
 
 % Print VHDL file neural_library.vhd, which holds constants, types, and
 % functions to be used in the stages of Synthesis and Simulation
 fprintf(fid3,'----------------------------------------------------------\n');
 fprintf(fid3,'-- Package neural_library contains the naming of some types\n');
 fprintf(fid3,'-- that are frequently used it the implementation, such\n');
 fprintf(fid3,'-- as "fixedX" or "fixedX_vector", and 2 very crucial\n');
 fprintf(fid3,'-- constants: "UPPER_LIMIT" and "DOWN_LIMIT". These two\n');
 fprintf(fid3,'-- arrange the integer size and fraction size respectively,\n');
 fprintf(fid3,'-- of the signals used to perform the detection scheme.\n');
 fprintf(fid3,'----------------------------------------------------------\n\n');
 fprintf(fid3,'LIBRARY ieee;\n');
 fprintf(fid3,'LIBRARY ieee_proposed;\n');
 fprintf(fid3,'USE ieee.std_logic_1164.all;\n');
 fprintf(fid3,'use ieee_proposed.fixed_pkg.all;\n\n');
 fprintf(fid3,'package neural_library is\n\n');
 fprintf(fid3,'  CONSTANT N_INPUTS    : integer := %d;\n',N_INPUTS);
 fprintf(fid3,'  CONSTANT N_HIDDEN    : integer := %d;\n',N_HIDDEN);
 fprintf(fid3,'  CONSTANT N_OUTPUTS   : integer := %d;\n',N_OUTPUTS);
 fprintf(fid3,'  CONSTANT N_BITS      : integer := %d;\n',integer_bits+fraction_bits);
 fprintf(fid3,'  CONSTANT UPPER_LIMIT : integer := %d;\n',integer_bits-1);
 fprintf(fid3,'  CONSTANT DOWN_LIMIT  : integer := %d;\n\n',-fraction_bits);
 fprintf(fid3,'  subtype fixedX        IS sfixed(%d downto %d);\n',integer_bits-1,-fraction_bits);
 fprintf(fid3,'  type fixedX_vector    IS array (INTEGER RANGE <>) OF fixedX;\n');
 fprintf(fid3,'  CONSTANT zero        : fixedX  := (others => ''0'');\n');
 fprintf(fid3,'  type hidden_node_modes IS (\n');
 fprintf(fid3,'      idle,\n');
 fprintf(fid3,'      multiply,\n');
 for i = 1:adder_tree1                         % Create N number of accumulate stages, where N is the size of the adder_tree
    fprintf(fid3,'      accumulate_%d,\n',i);
 end;
 fprintf(fid3,'      activation_function\n');

 fprintf(fid3,'  );\n');
 fprintf(fid3,'  type output_node_modes IS (\n');
 fprintf(fid3,'      idle,\n');
 fprintf(fid3,'      multiply,\n');
 for i = 1:adder_tree2-1                       % Create N number of accumulate stages, where N is the size of the adder_tree
    fprintf(fid3,'      accumulate_%d,\n',i);
 end;
 fprintf(fid3,'      accumulate_%d\n',adder_tree2);
 fprintf(fid3,'  );\n\n');
 
 
 fprintf(fid3,'--------------------------------------\n');
 fprintf(fid3,'-- Theses types are used to describe\n');
 fprintf(fid3,'-- the FSM of the Neural Network.\n');
 fprintf(fid3,'--------------------------------------\n\n');
 fprintf(fid3,'type ann_modes is (\n');
 fprintf(fid3,'  idle,\n');
 fprintf(fid3,'  run,\n');
 fprintf(fid3,'  run_next,\n');
 fprintf(fid3,'  turn_off_output\n');
 fprintf(fid3,');\n\n');
 fprintf(fid3,'type node_modes is (\n');
 fprintf(fid3,'  idle,\n');
 fprintf(fid3,'  run\n');
 fprintf(fid3,'	);\n\n');
 
 fprintf(fid3,'  type hidden_vector IS array (1 TO %d) OF STD_LOGIC_VECTOR(7 downto 0);\n',N_HIDDEN);
 
 fprintf(fid3,'  type input_vector IS\n');
 fprintf(fid3,'    record\n');
 for i = 1:N_INPUTS
    fprintf(fid3,'      %s   : STD_LOGIC_VECTOR(%d downto 0);\n',input_map{i},RTS_bits(i)-1);
 end;
 fprintf(fid3,'    end record;\n\n');
 
 fprintf(fid3,'  type ann_input_vector IS\n');
 fprintf(fid3,'    record\n');
 for i = 1:N_INPUTS
    fprintf(fid3,'      %s   : STD_LOGIC_VECTOR(%d downto 0);\n',input_map{i},compressed_RTS_bits(i)-1);
 end;
 fprintf(fid3,'    end record;\n\n');
 

 fprintf(fid3,'  CONSTANT hidden_bias : fixedX_vector(1 to %d) := (\n',length(neural.b{1}));          % Store the values of biases for hidden nodes
 for i = 1:length(neural.b{1})-1
     temp4 = sfi(neural.b{1}(i),integer_bits + fraction_bits ,fraction_bits);
     number = temp4.bin;
     fprintf(fid3,'                                           "%s",\n',number);
 end;
 temp4 = sfi(neural.b{1}(length(neural.b{1})),integer_bits + fraction_bits ,fraction_bits);
 number = temp4.bin;
 fprintf(fid3,'                                           "%s");\n',number);
 fprintf(fid3,'  CONSTANT output_bias : fixedX_vector(1 to %d) := (\n',length(neural.b{2}));
 for i = 1:length(neural.b{2})-1                                                                      % Store the values of biases for output nodes
     temp4 = sfi(neural.b{2}(i),integer_bits + fraction_bits ,fraction_bits);
     number = temp4.bin;
     fprintf(fid3,'                                           "%s",\n',number);
 end;
 temp4 = sfi(neural.b{2}(length(neural.b{2})),integer_bits + fraction_bits ,fraction_bits);
 number = temp4.bin;
 fprintf(fid3,'                                           "%s");\n\n',number);
 
fprintf(fid3,'--------------------------------------------------------------------\n');
fprintf(fid3,'-- These values and functions are needed for the testbench simulation\n');
fprintf(fid3,'---------------------------------------------------------------------\n');

fprintf(fid3,'  CONSTANT latency    : integer := %d;\n\n',13 + ceil(log2(N_INPUTS+1)) + ceil(log2(N_HIDDEN+1)));
fprintf(fid3,'  type input_bitvector IS\n');
fprintf(fid3,'    record\n');
for i = 1:N_INPUTS
   fprintf(fid3,'      %s   : BIT_VECTOR(%d downto 0);\n',input_map{i},RTS_bits(i)-1);
end;
fprintf(fid3,'    end record;\n\n');
 
fprintf(fid3,'  type ann_input_bitvector IS\n');
fprintf(fid3,'    record\n');
for i = 1:N_INPUTS
   fprintf(fid3,'      %s   : BIT_VECTOR(%d downto 0);\n',input_map{i},compressed_RTS_bits(i)-1);
end;
 fprintf(fid3,'    end record;\n\n');
 fprintf(fid3,'  CONSTANT vector_length   : integer := %d;\n',sum(compressed_RTS_bits));
 fprintf(fid3,'  type MATRIXES       IS ARRAY(1 to %d) OF BIT_VECTOR(vector_length-1 downto 0);     -- Change this value(5000) if it cannot hold the amount of errors\n',5000);   % Change this value(1000) if it cannot hold the amount of errors
 fprintf(fid3,'  type LUT_matrix     IS ARRAY(1 to %d) OF BIT_VECTOR(1 to N_OUTPUTS);\n\n',5000);
 
fprintf(fid3,'--------------------------------------------------------------------\n');
fprintf(fid3,'-- These components are used in the implementation\n');
fprintf(fid3,'---------------------------------------------------------------------\n\n');
fprintf(fid3,'COMPONENT log_sigmoid IS\n');
fprintf(fid3,'  PORT(\n');
fprintf(fid3,'    input	: IN fixedX;\n');
fprintf(fid3,'    enable  : IN STD_LOGIC;\n');
fprintf(fid3,'    CLK     : IN STD_LOGIC;\n');
fprintf(fid3,'    output  : OUT STD_LOGIC_VECTOR(7 downto 0)\n');
fprintf(fid3,'	 );\n');
fprintf(fid3,'END COMPONENT;\n\n');
fprintf(fid3,'COMPONENT hidden_node IS\n'); 
fprintf(fid3,'  GENERIC (\n');
fprintf(fid3,'    Num_Inputs : INTEGER := 5;\n');
fprintf(fid3,'    Position   : INTEGER\n');
fprintf(fid3,'  );\n');
fprintf(fid3,'  PORT (\n');
fprintf(fid3,'    input       : IN ann_input_vector;\n');
fprintf(fid3,'    node_en     : IN STD_LOGIC;\n');
fprintf(fid3,'    node_mode   : IN node_modes;\n');
fprintf(fid3,'    CLK         : IN STD_LOGIC;\n');
fprintf(fid3,'    node_flag   : BUFFER STD_LOGIC :=''1'';                       -- This instantiation means that, initially a node is ready for action\n');
fprintf(fid3,'    node_output : OUT STD_LOGIC_VECTOR(7 downto 0)\n');
fprintf(fid3,'  );\n');
fprintf(fid3,'END COMPONENT;\n\n');

fprintf(fid3,'COMPONENT output_node IS\n'); 
fprintf(fid3,'  GENERIC (\n');
fprintf(fid3,'    Num_Inputs : INTEGER := 5;\n');
fprintf(fid3,'    Position   : INTEGER\n');
fprintf(fid3,'  );\n');
fprintf(fid3,'  PORT (\n');
fprintf(fid3,'    input       : IN hidden_vector;\n');
fprintf(fid3,'    node_en     : IN STD_LOGIC;\n');
fprintf(fid3,'    node_mode   : IN node_modes;\n');
fprintf(fid3,'    CLK         : IN STD_LOGIC;\n');
fprintf(fid3,'    node_flag   : BUFFER STD_LOGIC :=''1'';                       -- This instantiation means that, initially a node is ready for action\n');
fprintf(fid3,'    node_output : OUT STD_LOGIC\n');
fprintf(fid3,'  );\n');
fprintf(fid3,'END COMPONENT;\n\n');

fprintf(fid3,'COMPONENT ann IS\n');
fprintf(fid3,'  GENERIC (                                             -- These generic values stand for:\n');
fprintf(fid3,'      N_I : INTEGER := N_INPUTS;                        -- N_I : Number of Inputs\n');
fprintf(fid3,'      N_H : INTEGER := N_HIDDEN;                        -- N_H : Number of Hidden Nodes\n');
fprintf(fid3,'      N_O : INTEGER := N_OUTPUTS                        -- N_O : Number of Output Nodes\n');
fprintf(fid3,'	);                                                    -- and regulate the size of the circuit\n');
	
fprintf(fid3,'	PORT (\n');
fprintf(fid3,'      input           : IN  ann_input_vector;\n');
fprintf(fid3,'      ann_mode        : IN  ann_modes;\n');
fprintf(fid3,'      CLK             : IN  STD_LOGIC;\n');
fprintf(fid3,'      Enable          : IN  STD_LOGIC :=''1'';\n');
fprintf(fid3,'      reset           : IN  STD_LOGIC :=''0'';\n');
fprintf(fid3,'      Ready           : OUT STD_LOGIC :=''1'';\n');
fprintf(fid3,'      output          : OUT STD_LOGIC_VECTOR(1 to N_OUTPUTS)\n');
fprintf(fid3,'	);\n');
fprintf(fid3,'END COMPONENT;\n\n');
 
 
fprintf(fid3,'--------------------------------------------------------------------\n');
fprintf(fid3,'-- These  functions are needed for the testbench simulation\n');
fprintf(fid3,'---------------------------------------------------------------------\n\n');
fprintf(fid3,'FUNCTION  to_sl(b: bit) return std_logic IS\n');
fprintf(fid3,'BEGIN\n');
fprintf(fid3,'  IF b=''1'' THEN\n');
fprintf(fid3,'    RETURN ''1'';\n');
fprintf(fid3,'  ELSE\n');
fprintf(fid3,'    RETURN ''0'';\n');
fprintf(fid3,'  END IF;\n\n');
fprintf(fid3,'END;\n\n');
fprintf(fid3,'FUNCTION to_slv(bv:bit_vector) return std_logic_vector IS\n');
fprintf(fid3,'  variable sv: std_logic_vector(bv''RANGE);\n');
fprintf(fid3,'BEGIN\n');
fprintf(fid3,'  FOR i IN bv''RANGE loop\n');
fprintf(fid3,'    sv(i) := to_sl(bv(i));\n');
fprintf(fid3,'  END LOOP;\n');
fprintf(fid3,'  return sv;\n');
fprintf(fid3,'END;\n\n');
fprintf(fid3,'end package neural_library;\n');
fclose(fid3);
 
 
 
% Print VHDL code for the hidden node
fprintf(fid4,'---------------------------------------------------\n');
fprintf(fid4,'-- Hidden nodes along with output nodes consist\n');
fprintf(fid4,'-- the processing units of the Neural Network.\n');
fprintf(fid4,'-- This specific piece of code is instantiated \n');
fprintf(fid4,'-- as many times as the user defined number of hidden \n');
fprintf(fid4,'-- nodes. Each instance calls a unique LUT module\n');
fprintf(fid4,'-- which replaces hardware-expensive multiplications.\n');
fprintf(fid4,'-- Additionally, each hidden node module infers a\n');
fprintf(fid4,'-- log_sigmoid sub-module creation.\n');
fprintf(fid4,'-- Hidden node uses an FSM to control its function,\n');
fprintf(fid4,'-- and when its flag is set to ''1'', it returns control\n');
fprintf(fid4,'-- to the central Neural Network control\n');
fprintf(fid4,'----------------------------------------------------\n\n');
fprintf(fid4,'LIBRARY ieee;\n');
fprintf(fid4,'LIBRARY ieee_proposed;\n');
fprintf(fid4,'use ieee.std_logic_1164.all;\n');
fprintf(fid4,'use ieee.std_logic_arith.all;\n');
fprintf(fid4,'use ieee.std_logic_unsigned.all;\n');
fprintf(fid4,'use ieee_proposed.fixed_pkg.all;\n');
fprintf(fid4,'use work.neural_library.all;\n');
fprintf(fid4,'use work.hidden_LUTS.all;\n\n');
fprintf(fid4,'ENTITY hidden_node is \n');
fprintf(fid4,'	GENERIC (                                               -- These generic values stand for:\n');
fprintf(fid4,'		Num_Inputs : INTEGER := 5;                          -- Number of inputs from previous layer\n');
fprintf(fid4,'		Position   : INTEGER                                -- Serial Number of Hidden node, passed by ann during instantiation\n');
fprintf(fid4,'	);\n');
fprintf(fid4,'	PORT (\n');
fprintf(fid4,'		input       : IN ann_input_vector;                  -- Input vector defined by user/system.\n');
fprintf(fid4,'		node_en     : IN STD_LOGIC;                         -- Incoming signal from ann module\n');
fprintf(fid4,'		node_mode   : IN node_modes;                        -- Incoming signal from ann module\n');
fprintf(fid4,'		CLK         : IN STD_LOGIC;                         -- Output signal, defines if node is ready to accept new values\n');
fprintf(fid4,'		node_flag   : BUFFER STD_LOGIC :=''1'';             -- This instantiation means that, initially a node is ready for action\n');
fprintf(fid4,'		node_output : OUT STD_LOGIC_VECTOR(7 downto 0)\n');
fprintf(fid4,'   );\n\n'); 
fprintf(fid4,'END ENTITY hidden_node;\n\n');
fprintf(fid4,'ARCHITECTURE hidden_node of hidden_node IS\n\n');
fprintf(fid4,'  signal bias             : fixedX := hidden_bias(Position);   -- Each hidden node points to a unique bias value from an array structure\n');
fprintf(fid4,'  signal weight_x_input   : fixedX_vector(1 to %d);\n',N_INPUTS);
fprintf(fid4,'  signal sig_input        : fixedX;\n');
fprintf(fid4,'  signal temp_accumulator : fixedX_vector(1 to %d);\n',N_INPUTS);      % The adder_tree scheme requires as many adders as the number of previous layer inputs
fprintf(fid4,'  signal node_state       : hidden_node_modes;\n');
fprintf(fid4,'  signal LUT_enable       : STD_LOGIC := ''0'';                -- This signal transfers control to the hidden Luts module\n');
fprintf(fid4,'  signal sig_enable       : STD_LOGIC := ''0'';                -- This signal transfers control to the log_sigmoid module (activation function)\n\n');
fprintf(fid4,'BEGIN\n\n');
fprintf(fid4,'-- Link each node to its corresponding hidden_LUT entity.\n');
fprintf(fid4,'-- This is achieved with ''IF Generate'' command, which\n');
fprintf(fid4,'-- infers the creation of the hidden_LUT submodule\n\n');
for i = 1:N_HIDDEN
    fprintf(fid4,'  node%d: IF (Position = %d) GENERATE\n',i,i);
    fprintf(fid4,'      lut%d: hiddenNode_%d port map(\n',i,i);
    fprintf(fid4,'                             CLK,\n');
    fprintf(fid4,'                             input,\n');
    fprintf(fid4,'                             LUT_enable,\n');
    fprintf(fid4,'                             weight_x_input\n');
    fprintf(fid4,'                         );\n');
    fprintf(fid4,'  END GENERATE node%d;\n\n',i);
end;
fprintf(fid4,'\n');
fprintf(fid4,'-- Link hidden node to log_sigmoid submodule. This\n');
fprintf(fid4,'-- submodule is instantiated only once in each node\n');
fprintf(fid4,'-- and performs the activation function\n\n');
fprintf(fid4,'  sigmoid_0 : log_sigmoid port map(\n');
fprintf(fid4,'							     sig_input,\n');
fprintf(fid4,'							     sig_enable,\n');
fprintf(fid4,'						         CLK,\n');
fprintf(fid4,'							     node_output\n');
fprintf(fid4,'						   );\n\n');
fprintf(fid4,'-- This process describes the FSM that controls the function\n');
fprintf(fid4,'-- of the hidden node. It is enabled when the incoming signals \n');
fprintf(fid4,'-- from ann ''node_en'' and ''node_mode'' are set to ''1'' and ''run''\n');
fprintf(fid4,'-- respectively. Its initial state ''idle'' is then changed and computations\n');
fprintf(fid4,'-- follow that calculate the output of the node for specific outputs\n\n');
fprintf(fid4,'PROCESS(CLK) IS \n\n');
fprintf(fid4,'BEGIN\n');
fprintf(fid4,'  IF (CLK''EVENT AND CLK = ''%d'') THEN\n',CLK_STATE);
fprintf(fid4,'    IF (node_en = ''1'') THEN\n');
fprintf(fid4,'      IF (sig_enable = ''1'') THEN\n');
fprintf(fid4,'        sig_enable <= ''0'';\n');
fprintf(fid4,'      ELSE\n');
fprintf(fid4,'		  CASE node_state IS\n');
fprintf(fid4,'          WHEN multiply => \n');
fprintf(fid4,'            LUT_enable <= ''0'';               -- Switch off hidden_LUT submodule\n');
fprintf(fid4,'            node_state <= accumulate_1;\n');
fprintf(fid4,'          WHEN accumulate_1 => \n');


% The next lines of codes descibe an algorithm that is used to print the
% exact number of 'temp_accumulator' registers, defined by the number of
% inputs from the previous layer

% ************************************************************************
% ** This adder tree scheme uses just two operands per operation. This
% ** adds a cost in terms of Hardware cycles. Alternatively, a scheme 
% ** with ternary adders could be used to reduce cycles as long as it 
% ** does not affect critical path. The challenge is to use dedicated
% ** code for ternary adders, oriented in the particular company's Hardware
% ** and modify it to be used for fixed type signals. Modification are
% ** also needed in the description of the adder tree scheme. Code for
% ** ternary adders is found : http://opencores.org/project,ternary_adder
% ************************************************************************

fprintf(fid4,'            --------------------------------------------------------------------------\n');
fprintf(fid4,'            -- This adder tree scheme uses just two operands per operation. This\n');
fprintf(fid4,'            -- adds a cost in terms of Hardware cycles. Alternatively, a scheme\n');
fprintf(fid4,'            -- with ternary adders could be used to reduce cycles as long as it\n');
fprintf(fid4,'            -- does not affect critical path. The challenge is to use dedicated\n');
fprintf(fid4,'            -- code for ternary adders, oriented in the particular company''s Hardware\n');
fprintf(fid4,'            -- and modify it to be used for fixed type signals. Modification are\n');
fprintf(fid4,'            -- also needed in the description of the adder tree scheme. Code for\n');
fprintf(fid4,'            -- ternary adders is found : http://opencores.org/project,ternary_adder\n');
fprintf(fid4,'            --------------------------------------------------------------------------\n');

index_hidden     = 0;
bias_used        = false;
odd_check        = zeros(1,adder_tree1); % Array used to store the stage in which an odd number of operands was used 
N_operands       = N_INPUTS+1;           % The number of operands to be added
adders_hidden    = fix(N_operands/2);    % The number of adders for each stage

if mod(N_operands,2) == 1
    odd_check(1) = 1;
    for i = 1:adders_hidden
        fprintf(fid4,'            temp_accumulator(%d) <= resize(weight_x_input(%d) + weight_x_input(%d),%d,-%d);\n',i,(i-1)*2+1,2*i,integer_bits-1,fraction_bits);
    end;
else
    for i = 1:adders_hidden-1
        fprintf(fid4,'            temp_accumulator(%d) <= resize(weight_x_input(%d) + weight_x_input(%d),%d,-%d);\n',i,(i-1)*2+1,2*i,integer_bits-1,fraction_bits);
    end;
        fprintf(fid4,'            temp_accumulator(%d) <= resize(bias + weight_x_input(%d),%d,-%d);\n',adders_hidden,(adders_hidden-1)*2+1,integer_bits-1,fraction_bits);
        bias_used = true;
end;
if N_operands > 2
    fprintf(fid4,'            node_state <= accumulate_%d; \n',2);
end;

        
for adder_stage = 2:adder_tree1
    fprintf(fid4,'          WHEN accumulate_%d => \n',adder_stage);
    index_hidden = index_hidden + adders_hidden;
    N_operands = adders_hidden;
    if mod(N_operands,2) == 1
        odd_check(adder_stage) = 1;
        if sum(odd_check) ==1
            index22 = index_hidden;
        end;
    end;
    adders_hidden = fix(N_operands/2);
    for i = 1:adders_hidden
        fprintf(fid4,'            temp_accumulator(%d) <= resize(temp_accumulator(%d) + temp_accumulator(%d),%d,-%d);\n',index_hidden+i,index_hidden-N_operands+2*i-1,index_hidden-N_operands+2*i,integer_bits-1,fraction_bits);
    end;
    if sum(odd_check) == 2
        if odd_check(1) == 1
            fprintf(fid4,'            temp_accumulator(%d) <= resize(bias + temp_accumulator(%d),%d,-%d);\n',index_hidden+adders_hidden+1,index_hidden-N_operands+2*adders_hidden+1,integer_bits-1,fraction_bits);
            bias_used = true;
        else
            fprintf(fid4,'            temp_accumulator(%d) <= resize(temp_accumulator(%d) + temp_accumulator(%d),%d,-%d);\n',index_hidden+adders_hidden+1,index22,index_hidden-N_operands+2*adders_hidden+1,integer_bits-1,fraction_bits);
        end;
        odd_check = zeros(1,adder_tree1);
        adders_hidden = adders_hidden+1;
    end;
    if adder_stage <adder_tree1
        fprintf(fid4,'            node_state <= accumulate_%d;\n',adder_stage+1); 
    end;
end;
if bias_used == false
     fprintf(fid4,'         WHEN accumulate_%d => \n',adder_tree1);
     fprintf(fid4,'            temp_accumulator(%d) <= resize(bias + temp_accumulator(%d),%d,-%d);\n',index_hidden+adders_hidden+1,index_hidden+adders_hidden,integer_bits-1,fraction_bits);
end;
fprintf(fid4,'            node_state <= activation_function;\n');
fprintf(fid4,'          WHEN activation_function => \n');
fprintf(fid4,'            sig_input     <= temp_accumulator(%d);\n',index_hidden+adders_hidden);
fprintf(fid4,'            sig_enable    <= ''1'';                              -- Switch on log_sigmoid submodule\n');                         
fprintf(fid4,'            node_state    <= idle;\n');
fprintf(fid4,'          WHEN idle => \n');
fprintf(fid4,'            CASE node_mode IS\n');
fprintf(fid4,'              WHEN run =>\n');
fprintf(fid4,'                node_flag  <= ''0'';                             -- Set node''s state as busy\n');                       
fprintf(fid4,'                LUT_enable <= ''1'';                             -- Switch on hidden_LUT submodule\n');
fprintf(fid4,'                node_state <= multiply;\n');
fprintf(fid4,'              WHEN idle =>\n');
fprintf(fid4,'                node_flag        <= ''1'';                       -- Set node''s state as ready\n');
fprintf(fid4,'                temp_accumulator <= (others => zero);            -- Reset the value of temp_accumulator\n');
fprintf(fid4,'            END CASE;\n');
fprintf(fid4,'          END CASE;\n');
fprintf(fid4,'      END IF;\n');
fprintf(fid4,'    END IF;\n');
fprintf(fid4,'  END IF;\n\n');
fprintf(fid4,'END PROCESS;\n\n');
fprintf(fid4,'END ARCHITECTURE hidden_node;');
fclose(fid4);



% Print VHDL code for the output node 
fprintf(fid5,'---------------------------------------------------\n');
fprintf(fid5,'-- Output nodes along with hidden nodes consist\n');
fprintf(fid5,'-- the processing units of the Neural Network.\n');
fprintf(fid5,'-- This specific piece of code is instantiated \n');
fprintf(fid5,'-- as many times as the data defined number of output \n');
fprintf(fid5,'-- nodes. Each instance infers a unique LUT module\n');
fprintf(fid5,'-- which replaces hardware-expensive multiplications.\n');
fprintf(fid5,'-- Output node uses an FSM to control its function,\n');
fprintf(fid5,'-- and when its flag is set to ''1'', it returns control\n');
fprintf(fid5,'-- to the central Neural Network control\n');
fprintf(fid5,'----------------------------------------------------\n\n');
fprintf(fid5,'LIBRARY ieee;\n');
fprintf(fid5,'LIBRARY ieee_proposed;\n');
fprintf(fid5,'use ieee.std_logic_1164.all;\n');
fprintf(fid5,'use ieee.std_logic_arith.all;\n');
fprintf(fid5,'use ieee.std_logic_unsigned.all;\n');
fprintf(fid5,'use ieee_proposed.fixed_pkg.all;\n');
fprintf(fid5,'use work.neural_library.all;\n');
fprintf(fid5,'use work.output_LUTS.all;\n\n');
fprintf(fid5,'ENTITY output_node is \n');
fprintf(fid5,'	GENERIC (                                           -- These generic values stand for:\n');
fprintf(fid5,'		Num_Inputs : INTEGER := 5;                      -- Number of inputs from previous layer\n');
fprintf(fid5,'		Position   : INTEGER                            -- Serial Number of Hidden node, passed by ann during instantiation\n');
fprintf(fid5,'  );\n');
fprintf(fid5,'  PORT (\n');
fprintf(fid5,'		input       : IN hidden_vector;                 -- Input vector as computed at hidden layer\n');
fprintf(fid5,'		node_en     : IN STD_LOGIC;                     -- Incoming signal from ann module\n');
fprintf(fid5,'		node_mode   : IN node_modes;                    -- Incoming signal from ann module\n');
fprintf(fid5,'		CLK         : IN STD_LOGIC;\n');
fprintf(fid5,'		node_flag   : BUFFER STD_LOGIC :=''1'';         -- This instantiation means that, initially a node is ready for action\n');
fprintf(fid5,'		node_output : OUT STD_LOGIC\n');
fprintf(fid5,'   );\n\n'); 
fprintf(fid5,'END ENTITY output_node;\n\n');
fprintf(fid5,'ARCHITECTURE output_node of output_node IS\n\n');
fprintf(fid5,'  signal bias             : fixedX := output_bias(Position);\n');
fprintf(fid5,'  signal weight_x_input   : fixedX_vector(1 to %d);\n',N_HIDDEN);
fprintf(fid5,'  signal temp_accumulator : fixedX_vector(1 to %d);\n',N_HIDDEN-1);
fprintf(fid5,'  signal node_state       : output_node_modes;\n');
fprintf(fid5,'  signal LUT_enable       : STD_LOGIC := ''0'';\n');
fprintf(fid5,'BEGIN\n\n');
fprintf(fid5,'-- Link each node to its corresponding output_LUT entity.\n');
fprintf(fid5,'-- This is achieved with ''IF Generate'' command, which\n');
fprintf(fid5,'-- infers the creation of the hidden_LUT submodule\n\n');
for i = 1:N_OUTPUTS
    fprintf(fid5,'  node%d: IF (Position = %d) GENERATE\n',i,i);
    fprintf(fid5,'      lut%d: outputNode_%d port map(\n',i,i);
    fprintf(fid5,'                             CLK,\n');
    fprintf(fid5,'                             input,\n');
    fprintf(fid5,'                             LUT_enable,\n');
    fprintf(fid5,'                             weight_x_input\n');
    fprintf(fid5,'                         );\n');
    fprintf(fid5,'  END GENERATE node%d;\n\n',i);
end;
fprintf(fid5,'\n\n');
fprintf(fid5,'-- This process describes the FSM that controls the function\n');
fprintf(fid5,'-- of the output node. It is enabled when the incoming signals \n');
fprintf(fid5,'-- from ann ''node_en'' and ''node_mode'' are set to ''1'' and ''run''\n');
fprintf(fid5,'-- respectively. Its initial state ''idle'' is then changed and computations\n');
fprintf(fid5,'-- follow that calculate the output of the node for specific outputs\n\n');
fprintf(fid5,'PROCESS(CLK) IS \n\n');
fprintf(fid5,'  variable final_accumulator   : fixedX;\n\n');
fprintf(fid5,'BEGIN\n');
fprintf(fid5,'  IF (CLK''EVENT AND CLK = ''%d'') THEN\n',CLK_STATE);
fprintf(fid5,'    IF (node_en = ''1'') THEN\n');
fprintf(fid5,'		  CASE node_state IS\n');
fprintf(fid5,'          WHEN multiply => \n');
fprintf(fid5,'            LUT_enable <= ''0'';              -- Switch off output_LUT submodule\n');
fprintf(fid5,'            node_state <= accumulate_1;\n');
fprintf(fid5,'          WHEN accumulate_1 => \n');

% The next lines of code descibe an algorithm that is used to print the
% exact number of 'temp_accumulator' registers, defined by the number of
% inputs from the previous layer

% ************************************************************************
% ** This adder tree scheme uses just two operands per operation. This
% ** adds a cost in terms of Hardware cycles. Alternatively, a scheme 
% ** with ternary adders could be used to reduce cycles as long as it 
% ** does not affect critical path. The challenge is to use dedicated
% ** code for ternary adders, oriented in the particular company's Hardware
% ** and modify it to be used for fixed type signals. Modification are
% ** also needed in the description of the adder tree scheme. Code for
% ** ternary adders is found : http://opencores.org/project,ternary_adder
% ************************************************************************

fprintf(fid5,'            --------------------------------------------------------------------------\n');
fprintf(fid5,'            -- This adder tree scheme uses just two operands per operation. This\n');
fprintf(fid5,'            -- adds a cost in terms of Hardware cycles. Alternatively, a scheme\n');
fprintf(fid5,'            -- with ternary adders could be used to reduce cycles as long as it\n');
fprintf(fid5,'            -- does not affect critical path. The challenge is to use dedicated\n');
fprintf(fid5,'            -- code for ternary adders, oriented in the particular company''s Hardware\n');
fprintf(fid5,'            -- and modify it to be used for fixed type signals. Modification are\n');
fprintf(fid5,'            -- also needed in the description of the adder tree scheme. Code for\n');
fprintf(fid5,'            -- ternary adders is found : http://opencores.org/project,ternary_adder\n');
fprintf(fid5,'            --------------------------------------------------------------------------\n');

index_output    = 0;
bias_added      = false;
odd_flag        = zeros(1,adder_tree2);
No_operands     = N_HIDDEN+1;
adders_output   = fix(No_operands/2);

if mod(No_operands,2) == 1
    odd_flag(1) = 1;
    for i = 1:adders_output
        fprintf(fid5,'            temp_accumulator(%d) <= resize(weight_x_input(%d) + weight_x_input(%d),%d,-%d);\n',i,(i-1)*2+1,2*i,integer_bits-1,fraction_bits);
    end;
else
    for i = 1:adders_output-1
        fprintf(fid5,'            temp_accumulator(%d) <= resize(weight_x_input(%d) + weight_x_input(%d),%d,-%d);\n',i,(i-1)*2+1,2*i,integer_bits-1,fraction_bits);
    end;
        fprintf(fid5,'            temp_accumulator(%d) <= resize(bias + weight_x_input(%d),%d,-%d);\n',adders_output,(adders_output-1)*2+1,integer_bits-1,fraction_bits);
        bias_added = true;
end;
if No_operands > 2
    fprintf(fid5,'            node_state <= accumulate_%d; \n',2);
end;
        
for adder_stage = 2:adder_tree2
    fprintf(fid5,'          WHEN accumulate_%d => \n',adder_stage);
    index_output = index_output + adders_output;
    No_operands = adders_output;
    if mod(No_operands,2) == 1
        odd_flag(adder_stage) = 1;
        if sum(odd_flag) ==1
            index_2 = index_output;
        end;
    end;
    adders_output = fix(No_operands/2);
    for i = 1:adders_output
        if i == adders_output && adder_stage == adder_tree2
            fprintf(fid5,'            final_accumulator := resize(temp_accumulator(%d) + temp_accumulator(%d),%d,-%d);\n',index_output-No_operands+2*i-1,index_output-No_operands+2*i,integer_bits-1,fraction_bits);
        else
            fprintf(fid5,'            temp_accumulator(%d) <= resize(temp_accumulator(%d) + temp_accumulator(%d),%d,-%d);\n',index_output+i,index_output-No_operands+2*i-1,index_output-No_operands+2*i,integer_bits-1,fraction_bits);
        end;
    end;
    if sum(odd_flag) == 2
        if odd_flag(1) == 1
            if adder_stage == adder_tree2
                fprintf(fid5,'            final_accumulator := resize(bias + temp_accumulator(%d),%d,-%d);\n',index_output-No_operands+2*adders_output+1,integer_bits-1,fraction_bits);
                bias_added = true;
            else 
                fprintf(fid5,'            temp_accumulator(%d) <= resize(bias + temp_accumulator(%d),%d,-%d);\n',index_output+adders_output+1,index_output-No_operands+2*adders_output+1,integer_bits-1,fraction_bits);
                bias_added = true;
            end;
        else
            if adder_stage == adder_tree2
                fprintf(fid5,'            final_accumulator := resize(temp_accumulator(%d) + temp_accumulator(%d),%d,-%d);\n',index_2,index_output-No_operands+2*adders_output+1,integer_bits-1,fraction_bits);
            else
                fprintf(fid5,'            temp_accumulator(%d) <= resize(temp_accumulator(%d) + temp_accumulator(%d),%d,-%d);\n',index_output+adders_output+1,index_2,index_output-No_operands+2*adders_output+1,integer_bits-1,fraction_bits);
            end;
        end;
        odd_flag = zeros(1,adder_tree2);
        adders_output = adders_output+1;
    end;
    if adder_stage <adder_tree2
        fprintf(fid5,'            node_state <= accumulate_%d;\n',adder_stage+1); 
    end;
end;
if bias_added == false
     fprintf(fid5,'         WHEN accumulate_%d => \n',adder_tree2);
     fprintf(fid5,'            final_accumulator := resize(bias + temp_accumulator(%d),%d,-%d);\n',index_output+adders_output,integer_bits-1,fraction_bits);
end;

fprintf(fid5,'            node_output <= NOT final_accumulator(UPPER_LIMIT);\n');
fprintf(fid5,'            node_flag   <= ''1'';\n');
fprintf(fid5,'            node_state  <= idle;\n');
fprintf(fid5,'          WHEN idle => \n');
fprintf(fid5,'             CASE node_mode IS\n');
fprintf(fid5,'               WHEN run =>\n');
fprintf(fid5,'                 node_flag  <= ''0'';                           -- Set node''s state as busy\n');
fprintf(fid5,'                 LUT_enable <= ''1'';                           -- Switch on outpu_LUT submodule\n');
fprintf(fid5,'                 node_state <= multiply;\n');
fprintf(fid5,'               WHEN idle =>\n');
fprintf(fid5,'                 node_flag        <= ''1'';                     -- Set node''s state as ready\n');
fprintf(fid5,'                 temp_accumulator <= (others => zero);          -- Reset the value of temp_accumulator\n');
fprintf(fid5,'             END CASE;\n');
fprintf(fid5,'          END CASE;\n');
fprintf(fid5,'        END IF;\n');
fprintf(fid5,'   END IF;\n\n');
fprintf(fid5,'END PROCESS;\n\n');
fprintf(fid5,'END ARCHITECTURE output_node;');
fclose(fid5);



% Print VHDL code for pre_hybrid implemenation 
fprintf(fid6,'----------------------------------------------------\n');
fprintf(fid6,'-- Pre_hybrid module is not the final implementation,\n');
fprintf(fid6,'-- it uses only Neural Network to produce the final.\n');
fprintf(fid6,'-- In order to obtain the final implementation, we \n');
fprintf(fid6,'-- should simulate the results of the current, and \n');
fprintf(fid6,'-- the complementary LUTs will be completed with the \n');
fprintf(fid6,'-- miscalculated cases of the Neural Network.\n');
fprintf(fid6,'----------------------------------------------------\n\n');
fprintf(fid6,'LIBRARY ieee;\n');
fprintf(fid6,'LIBRARY ieee_proposed;\n');
fprintf(fid6,'use ieee.std_logic_1164.all;\n');
fprintf(fid6,'use ieee.std_logic_arith.all;\n');
fprintf(fid6,'use ieee.std_logic_unsigned.all;\n');
fprintf(fid6,'use ieee_proposed.fixed_pkg.all;\n');
fprintf(fid6,'use work.neural_library.all;\n\n');
fprintf(fid6,'ENTITY pre_hybrid IS\n');
fprintf(fid6,'  PORT (\n');
fprintf(fid6,'    input            : IN  input_vector;\n');
fprintf(fid6,'    CLK              : IN  STD_LOGIC;\n');
fprintf(fid6,'    new_input_vector : OUT STD_LOGIC_VECTOR(vector_length-1 downto 0);\n');
fprintf(fid6,'    output           : OUT STD_LOGIC_VECTOR(1 to N_OUTPUTS);\n');
fprintf(fid6,'    output_flag      : OUT STD_LOGIC\n');
fprintf(fid6,'  );\n');
fprintf(fid6,'END ENTITY pre_hybrid;\n\n');
fprintf(fid6,'ARCHITECTURE pre_hybrid OF pre_hybrid IS\n\n');
fprintf(fid6,'  type stages IS (\n');
fprintf(fid6,'    read_input,\n');
fprintf(fid6,'    correct,\n');
fprintf(fid6,'    drive_output\n');
fprintf(fid6,'  );\n\n');
fprintf(fid6,'  signal stage               : stages;\n');
fprintf(fid6,'  signal hold_input          : input_vector;\n');
fprintf(fid6,'  signal new_input           : ann_input_vector;\n');
fprintf(fid6,'  signal enable              : STD_LOGIC;\n');
fprintf(fid6,'  signal ann_ready           : STD_LOGIC;\n');
fprintf(fid6,'  signal ann_stop            : STD_LOGIC := ''0'';\n');
fprintf(fid6,'  signal reg_output          : STD_LOGIC_VECTOR(1 to N_OUTPUTS);\n');
fprintf(fid6,'  signal ann_output          : STD_LOGIC_VECTOR(1 to N_OUTPUTS);\n');
fprintf(fid6,'  signal ann_function        : ann_modes;\n\n');
fprintf(fid6,'BEGIN\n\n');
fprintf(fid6,'  ann0 : ann generic map ( N_INPUTS,\n');
fprintf(fid6,'                           N_HIDDEN,\n');
fprintf(fid6,'                           N_OUTPUTS\n');
fprintf(fid6,'             )\n');
fprintf(fid6,'             port map    ( new_input,\n');
fprintf(fid6,'                           ann_function,\n');
fprintf(fid6,'                           CLK,\n');
fprintf(fid6,'                           enable,\n');
fprintf(fid6,'                           ann_stop,\n');
fprintf(fid6,'                           ann_ready,\n');
fprintf(fid6,'                           ann_output\n');
fprintf(fid6,'             );\n\n');
fprintf(fid6,'PROCESS(CLK) IS\n\n');
fprintf(fid6,'  variable input_flag : STD_LOGIC_VECTOR(1 to N_INPUTS) :=(others =>''0'');\n');
fprintf(fid6,'  variable flag       : STD_LOGIC := ''0'';\n\n');
fprintf(fid6,'BEGIN\n ');
fprintf(fid6,'  IF (CLK''EVENT AND CLK = ''%d'') THEN \n',CLK_STATE);
fprintf(fid6,'      CASE stage IS\n');
fprintf(fid6,'        WHEN read_input =>\n');
for i = 1:N_INPUTS
    fprintf(fid6,'          IF (hold_input.%s /= input.%s) THEN\n',input_map{i},input_map{i});
    fprintf(fid6,'            hold_input.%s <= input.%s;\n',input_map{i},input_map{i});
    fprintf(fid6,'            input_flag(%d)       := ''1'';\n',i);
    fprintf(fid6,'            CASE input.%s IS\n',input_map{i});
    for j = 1:size(normalized_list{i},1);
        fprintf(fid6,'              WHEN "%s"  => new_input.%s <= "%s";\n',binary_list{i,j},input_map{i},compressed_list{i,j});
    end;
    fprintf(fid6,'              WHEN others => NULL;\n');
    fprintf(fid6,'            END CASE;\n');
    fprintf(fid6,'          ELSE\n');
    fprintf(fid6,'            input_flag(%d)  := ''0'';\n',i);
    fprintf(fid6,'          END IF;\n');
end;

% Print switch criteria
fprintf(fid6,'          flag := '); 
for i = 1:N_INPUTS-1
    fprintf(fid6,'input_flag(%d) OR ',i);
end;
fprintf(fid6,'input_flag(%d);\n',N_INPUTS);

fprintf(fid6,'          IF (flag = ''1'') THEN\n');
fprintf(fid6,'            enable       <= ''1'';\n');
fprintf(fid6,'            ann_function <= run;\n');
fprintf(fid6,'            stage        <= correct;\n');
fprintf(fid6,'            output_flag  <= ''0'';\n');
fprintf(fid6,'          ELSE\n');
fprintf(fid6,'            enable       <= ''0'';\n');
fprintf(fid6,'            ann_function <= idle;\n');
fprintf(fid6,'            output_flag  <= ''1'';\n');
fprintf(fid6,'          END IF;\n');
fprintf(fid6,'        WHEN correct =>\n');
fprintf(fid6,'    -- Here Simulation is going to add complementary LUTs\n\n');
fprintf(fid6,'          ann_function <= idle;\n');
fprintf(fid6,'          stage        <= drive_output;\n');
fprintf(fid6,'        WHEN drive_output =>\n');
fprintf(fid6,'          IF (ann_ready = ''1'') THEN\n');
fprintf(fid6,'            output <= ann_output;\n');
fprintf(fid6,'            output_flag <= ''1'';\n');
fprintf(fid6,'            new_input_vector <= ');
for i = 1:N_INPUTS-1
    fprintf(fid6,' new_input.%s &',input_map{i});
end;
fprintf(fid6,' new_input.%s;\n',input_map{N_INPUTS});
fprintf(fid6,'            enable          <= ''0'';\n');
fprintf(fid6,'            stage           <= read_input;\n');
fprintf(fid6,'          END IF;\n'); 
fprintf(fid6,'      END CASE;\n');
fprintf(fid6,'  END IF;\n');
fprintf(fid6,'END PROCESS;\n');
fprintf(fid6,'END ARCHITECTURE;');
fclose(fid6);



% Print VHDL file for Testbench
fprintf(fid7,'---------------------------------------------------\n');
fprintf(fid7,'-- This preliminary testbench fulfills 2 purposes:\n');
fprintf(fid7,'-- 1) Production of the final hybrid implementation\n');
fprintf(fid7,'-- 2) Evaluation of the effectiveness of current \n');
fprintf(fid7,'--    Neural Network on specific dataset.\n');
fprintf(fid7,'---------------------------------------------------\n');
fprintf(fid7,'LIBRARY ieee;\n');
fprintf(fid7,'LIBRARY ieee_proposed;\n');
fprintf(fid7,'use ieee.std_logic_1164.ALL;\n');
fprintf(fid7,'use ieee.math_real.all;\n');
fprintf(fid7,'use work.neural_library.all;\n');
fprintf(fid7,'use ieee_proposed.fixed_pkg.all;\n');
fprintf(fid7,'use std.textio.all;\n\n');
fprintf(fid7,'ENTITY testbench IS\n');
fprintf(fid7,'END testbench;\n\n');
fprintf(fid7,'ARCHITECTURE behavior OF testbench IS\n\n');
fprintf(fid7,'  -- Component Declaration for the Unit Under Test (UUT)\n\n');
fprintf(fid7,'  COMPONENT pre_hybrid IS\n');
fprintf(fid7,'    PORT (\n');
fprintf(fid7,'       input            : IN  input_vector;\n');
fprintf(fid7,'       CLK              : IN  STD_LOGIC;\n');
fprintf(fid7,'       new_input_vector : OUT STD_LOGIC_VECTOR(vector_length-1 downto 0);\n');
fprintf(fid7,'       output           : OUT STD_LOGIC_VECTOR(1 to N_OUTPUTS);\n');
fprintf(fid7,'       output_flag      : OUT STD_LOGIC\n');
fprintf(fid7,'    );\n');
fprintf(fid7,'  END COMPONENT;\n\n');
fprintf(fid7,'  type states IS (\n');
fprintf(fid7,'           first,\n');
fprintf(fid7,'           second,\n');
fprintf(fid7,'           third,\n');
fprintf(fid7,'           fourth\n');
fprintf(fid7,'  );\n\n');	
fprintf(fid7,'  -- Signals\n\n');
fprintf(fid7,'  CONSTANT N_EXAMPLES       : integer := %d;                   -- This value must always meet the size of the dataset.\n',N_ROWS);
fprintf(fid7,'                                                               -- Change if using a different dataset\n');
fprintf(fid7,'  signal hybrid_input       : input_vector ;\n');
fprintf(fid7,'  signal hybrid_output      : STD_LOGIC_VECTOR(1 TO N_OUTPUTS);\n');
fprintf(fid7,'  signal hybrid_output_flag : STD_LOGIC;\n');
fprintf(fid7,'  signal test_output_signal : BIT_VECTOR(1 TO N_OUTPUTS);\n');
fprintf(fid7,'  signal new_input_vector   : STD_LOGIC_VECTOR(vector_length-1 downto 0);\n');
fprintf(fid7,'  signal CLK                : STD_LOGIC := ''0'';\n\n');
fprintf(fid7,'  signal wait_counter       : integer;\n');
fprintf(fid7,'  signal counter            : integer := 1;\n');
fprintf(fid7,'  signal ERROR_MATRIX       : MATRIXES;\n');
fprintf(fid7,'  signal LUT_output         : LUT_matrix;\n');
fprintf(fid7,'  signal num_cases          : integer := 0;\n');
fprintf(fid7,'  signal state              : states :=first;\n\n\n');
fprintf(fid7,'  -- Clock period definitions\n');
fprintf(fid7,'  constant CLK_period : time := 10 ns;\n\n');
fprintf(fid7,'  -- File definitions\n');
fprintf(fid7,'  FILE inputfile    : text OPEN read_mode  IS "%s";\n',strcat(CurrentFolder,'/inputs.txt'));        % Use CurrentFolder variable to reconstruct the folder path
fprintf(fid7,'  FILE outputfile   : text OPEN read_mode  IS "%s";\n',strcat(CurrentFolder,'/outputs.txt'));
fprintf(fid7,'  FILE hybridfile   : text OPEN read_mode  IS "%s";\n',strcat(CurrentFolder,'/pre_hybrid.vhd'));
fprintf(fid7,'  FILE hybrid_part1 : text OPEN read_mode  IS "%s";\n',strcat(CurrentFolder,'/pre_hybrid_part1.vhd'));
fprintf(fid7,'  FILE hybrid_part2 : text OPEN read_mode  IS "%s";\n',strcat(CurrentFolder,'/pre_hybrid_part2.vhd'));
fprintf(fid7,'  FILE final        : text OPEN write_mode IS "%s";\n',strcat(CurrentFolder,'/hybrid.vhd'));
fprintf(fid7,'  FILE report_file  : text OPEN write_mode IS "%s";\n\n\n',strcat(CurrentFolder,'/report.txt'));

fprintf(fid7,'BEGIN\n\n');
fprintf(fid7,'  -- Instantiate the Unit Under Test (UUT\n');
fprintf(fid7,'  uut: pre_hybrid PORT MAP (\n');
fprintf(fid7,'                    input             => hybrid_input,\n');
fprintf(fid7,'                    CLK               => CLK,\n');
fprintf(fid7,'                    new_input_vector  => new_input_vector,\n');
fprintf(fid7,'                    output            => hybrid_output,\n');
fprintf(fid7,'                    output_flag       => hybrid_output_flag\n');
fprintf(fid7,'                  );\n\n');
fprintf(fid7,'  -- Clock process definitions\n');
fprintf(fid7,'  CLK_process : Process\n');
fprintf(fid7,'  BEGIN\n');
fprintf(fid7,'    CLK <= ''0'';\n');
fprintf(fid7,'    wait for CLK_period/2;\n');
fprintf(fid7,'    CLK <= ''1'';\n');
fprintf(fid7,'    wait for CLK_period/2;\n');
fprintf(fid7,'  END process;\n\n');
fprintf(fid7,'read_input : process(CLK) IS\n\n');
fprintf(fid7,'-- This process simulates the function of hybrid implementation.\n');
fprintf(fid7,'-- Four separate states perform sequentially, and when reaching\n');
fprintf(fid7,'-- the final state, the tasks that are completed are:\n');
fprintf(fid7,'-- 1) Extracting the final hybrid implementation described in \n');
fprintf(fid7,'--    file "hybrid.vhd"\n');
fprintf(fid7,'-- 2) Printing a report file that shows important aspects of our\n');
fprintf(fid7,'--    implementation, such as latency expressed in Hardware cycles,\n');
fprintf(fid7,'--    and the percentage of miscalculated input combinations from\n');
fprintf(fid7,'--    the Neural Network alone.\n\n');
fprintf(fid7,'  variable input_line     : line;\n');
fprintf(fid7,'  variable output_line    : line;\n');
fprintf(fid7,'  variable dataline       : line;\n');
fprintf(fid7,'  variable writer         : line;\n');
fprintf(fid7,'  variable new_line       : line;\n');
fprintf(fid7,'  variable test_input     : input_bitvector;\n');
fprintf(fid7,'  variable test_output    : BIT_VECTOR(1 TO N_OUTPUTS);\n');
fprintf(fid7,'  variable test_vector    : STD_LOGIC_VECTOR(vector_length-1 downto 0);\n\n');
fprintf(fid7,'  variable misses         : integer := 0;\n');
fprintf(fid7,'  variable percentage     : integer;\n');
fprintf(fid7,'  variable perc_real      : real;\n');
fprintf(fid7,'  variable no_train_flag  : STD_LOGIC := ''0'';\n\n');

fprintf(fid7,'BEGIN\n\n');
fprintf(fid7,'  IF (CLK''EVENT AND CLK = ''%d'') THEN\n',CLK_STATE);
fprintf(fid7,'    IF (wait_counter > 0) THEN\n');
fprintf(fid7,'      wait_counter <= wait_counter - 1;\n');
fprintf(fid7,'    ELSE\n');
fprintf(fid7,'      CASE state IS\n');
fprintf(fid7,'        WHEN first =>\n');
fprintf(fid7,'          readline(inputfile,input_line);\n');
for i = 1:N_INPUTS
    fprintf(fid7,'          read(input_line,test_input.%s);\n',input_map{i});
    fprintf(fid7,'          hybrid_input.%s <= to_slv(test_input.%s);\n',input_map{i},input_map{i});
end;
fprintf(fid7,'          readline(outputfile,output_line);\n');
fprintf(fid7,'          FOR i IN 1 to N_OUTPUTS LOOP\n');
fprintf(fid7,'            read(output_line,test_output(i));\n');
fprintf(fid7,'            test_output_signal(i) <= test_output(i);\n');
fprintf(fid7,'          END LOOP;\n');
fprintf(fid7,'          wait_counter <= latency + 1;\n');
fprintf(fid7,'          num_cases    <= num_cases + 1;\n');
fprintf(fid7,'          state        <= second;\n');
fprintf(fid7,'        WHEN second =>\n');

if No_train_enable == 1
    fprintf(fid7,'          CASE num_cases IS\n');
    for i = 1: length(index)
        fprintf(fid7,'            WHEN %d    => no_train_flag := ''1'';\n',index(i));
    end;
    fprintf(fid7,'            WHEN others    => no_train_flag := ''0'';\n');
    fprintf(fid7,'          END CASE;\n');
end;

fprintf(fid7,'          FOR i IN 1 to N_OUTPUTS LOOP\n');
fprintf(fid7,'            assert (test_output_signal(i)  = to_bit(hybrid_output(i)))\n');
fprintf(fid7,'            report "Wrong Result in Output : " & integer''image(i) & " at input_vector: "&integer''image(num_cases);\n');
fprintf(fid7,'          END LOOP;\n');
fprintf(fid7,'          IF (test_output_signal  /= to_bitvector(hybrid_output) OR no_train_flag = ''1'') THEN\n');
fprintf(fid7,'            ERROR_MATRIX(counter) <= to_bitvector(new_input_vector);\n');
fprintf(fid7,'            LUT_output(counter)   <= test_output_signal;\n');
fprintf(fid7,'            counter               <= counter + 1;\n');
fprintf(fid7,'          END IF;\n');
fprintf(fid7,'          IF (num_cases = N_EXAMPLES) THEN\n');
fprintf(fid7,'			  state <= third;\n');
fprintf(fid7,'          ELSE\n');
fprintf(fid7,'            state <= first;\n');
fprintf(fid7,'			END IF;\n');
fprintf(fid7,'        WHEN third =>\n');   
fprintf(fid7,'          report "END OF SIMULATION";\n');
fprintf(fid7,'          while NOT ENDFILE (hybrid_part1) LOOP\n');
fprintf(fid7,'            readline(hybrid_part1,input_line);\n');
fprintf(fid7,'            writeline(final,      input_line);\n');
fprintf(fid7,'          END LOOP;\n');
fprintf(fid7,'          write(writer,"          test_vector := ");\n');
for i =1:N_INPUTS-1
    fprintf(fid7,'          write(writer,"new_input.%s & ");\n',input_map{i});
end;
fprintf(fid7,'          write(writer,"new_input.%s;");\n',input_map{N_INPUTS});
fprintf(fid7,'          writeline(final,writer);\n');

fprintf(fid7,'            IF (counter > 1) THEN\n');
fprintf(fid7,'              write(writer,"        CASE test_vector IS");\n');
fprintf(fid7,'              writeline(final,writer);\n');
fprintf(fid7,'              FOR i IN 1 to counter-1 LOOP\n');
fprintf(fid7,'                write(writer,"          WHEN """);\n');
fprintf(fid7,'                write(writer,ERROR_MATRIX(i));\n');
fprintf(fid7,'                write(writer,"""  =>  LUT_output <= """);\n');
fprintf(fid7,'                write(writer,LUT_output(i));\n');
fprintf(fid7,'                write(writer,""";");\n');
fprintf(fid7,'                writeline(final,writer);\n');
fprintf(fid7,'              END LOOP;\n');
fprintf(fid7,'              write(writer,"          WHEN others        => LUT_decision := ''0'';");\n');
fprintf(fid7,'              writeline(final,writer);\n');
fprintf(fid7,'              write(writer,"        END CASE;");\n');
fprintf(fid7,'              writeline(final,writer);\n');
fprintf(fid7,'            ELSE\n');
fprintf(fid7,'              write(writer,"          LUT_decision := ''0'';");\n');
fprintf(fid7,'              writeline(final,writer);\n');
fprintf(fid7,'            END IF;\n');

fprintf(fid7,'          while NOT ENDFILE (hybrid_part2) LOOP\n');
fprintf(fid7,'            readline(hybrid_part2,input_line);\n');
fprintf(fid7,'            writeline(final,        input_line);\n');
fprintf(fid7,'          END LOOP;\n');
fprintf(fid7,'            state <= fourth;\n');
fprintf(fid7,'        WHEN fourth =>\n');
fprintf(fid7,'          misses := counter - 1;\n');
fprintf(fid7,'          perc_real := real (100 * misses) / real(N_EXAMPLES * N_OUTPUTS);\n');
fprintf(fid7,'          percentage := integer (perc_real);\n');
fprintf(fid7,'          write(writer,"BUILD NEURAL NETWORK");\n');
fprintf(fid7,'          writeline(report_file,writer);\n');
fprintf(fid7,'          write(writer,"Number of hidden neurons : %d ");\n',N_HIDDEN);
fprintf(fid7,'          writeline(report_file,writer);\n');
fprintf(fid7,'          write(writer,"Number of misses = ");\n');
fprintf(fid7,'          write(writer,misses);\n');
fprintf(fid7,'          writeline(report_file,writer);\n');
fprintf(fid7,'          write(writer,"Number of cases = ");\n');
fprintf(fid7,'          write(writer,N_EXAMPLES * N_OUTPUTS);\n');
fprintf(fid7,'          writeline(report_file,writer);\n');
fprintf(fid7,'          write(writer,"Percentage of wrong predictions = ");\n');
fprintf(fid7,'          write(writer,percentage);\n');
fprintf(fid7,'          write(writer," %% ");\n');
fprintf(fid7,'          writeline(report_file,writer);\n');
fprintf(fid7,'          write(writer,"Latency = ");\n');
fprintf(fid7,'          write(writer,latency);\n');
fprintf(fid7,'          writeline(report_file,writer);\n');
fprintf(fid7,'          wait_counter <= 1000000000;\n');
fprintf(fid7,'        END CASE;\n');
fprintf(fid7,'      END IF;\n');
fprintf(fid7,'  END IF;\n');
fprintf(fid7,'END PROCESS;\n\n');
fprintf(fid7,'END ARCHITECTURE;');
fclose(fid7);



% Print VHDL for final Implementation
fprintf(fid8,'------------------------------------------------------------\n');
fprintf(fid8,'-- Final hybrid implementation. An FSM controls\n');
fprintf(fid8,'-- the function of this module.Its possible states\n');
fprintf(fid8,'-- 1) read_input: recognize differentiation in input,\n');
fprintf(fid8,'--    compress input signals and decide whether that \n');
fprintf(fid8,'--    differentiation could trigger Scenario switch.\n');
fprintf(fid8,'-- 2) correct: search in the complementary LUTs if for\n');
fprintf(fid8,'--    the particular input combination exists an entry.\n');
fprintf(fid8,'--    If it does, Neural Network computations are bypassed\n');
fprintf(fid8,'--    and output is provide by the LUT entry. The final \n');
fprintf(fid8,'--    state would be drive_LUTs. If there is no such entry\n');
fprintf(fid8,'--    in the LUT, final output is straight-forward\n');
fprintf(fid8,'--    the outcome of neural network computations.\n');
fprintf(fid8,'-- 3) drive_ann: The first alternative of output stages\n');
fprintf(fid8,'--    is selected when the combination of inputs does not\n');
fprintf(fid8,'--    match the entries in the LUT.\n');
fprintf(fid8,'-- 4) drive_LUTS: The other alternative of output stages\n');
fprintf(fid8,'--    is selected when for the combination of input exists an\n');
fprintf(fid8,'--    entry in the LUT.\n\n');
fprintf(fid8,'------------------------------------------------------------\n');
fprintf(fid8,'LIBRARY ieee;\n');
fprintf(fid8,'LIBRARY ieee_proposed;\n');
fprintf(fid8,'use ieee.std_logic_1164.all;\n');
fprintf(fid8,'use ieee.std_logic_arith.all;\n');
fprintf(fid8,'use ieee.std_logic_unsigned.all;\n');
fprintf(fid8,'use ieee_proposed.fixed_pkg.all;\n');
fprintf(fid8,'use work.neural_library.all;\n\n');
fprintf(fid8,'ENTITY hybrid IS\n');
fprintf(fid8,'  PORT (\n');
fprintf(fid8,'    input            : IN  input_vector;\n');
fprintf(fid8,'    CLK              : IN  STD_LOGIC;\n');
fprintf(fid8,'    output           : OUT STD_LOGIC_VECTOR(1 to N_OUTPUTS);\n');
fprintf(fid8,'    output_flag      : OUT STD_LOGIC\n');
fprintf(fid8,'  );\n');
fprintf(fid8,'END ENTITY hybrid;\n\n');
fprintf(fid8,'ARCHITECTURE hybrid OF hybrid IS\n\n');
fprintf(fid8,'  type stages IS (\n');
fprintf(fid8,'    read_input,\n');
fprintf(fid8,'    correct,\n');
fprintf(fid8,'    drive_ann,\n');
fprintf(fid8,'    drive_LUTS\n');
fprintf(fid8,'  );\n\n');
fprintf(fid8,'  signal stage               : stages;\n');
fprintf(fid8,'  signal hold_input          : input_vector;\n');
fprintf(fid8,'  signal new_input           : ann_input_vector;\n');
fprintf(fid8,'  signal enable              : STD_LOGIC;\n');
fprintf(fid8,'  signal ann_ready           : STD_LOGIC;\n');
fprintf(fid8,'  signal ann_stop            : STD_LOGIC := ''0'';\n');
fprintf(fid8,'  signal reg_output          : STD_LOGIC_VECTOR(1 to N_OUTPUTS);\n');
fprintf(fid8,'  signal ann_output          : STD_LOGIC_VECTOR(1 to N_OUTPUTS);\n');
fprintf(fid8,'  signal ann_function        : ann_modes;\n');
fprintf(fid8,'  signal LUT_output          : STD_LOGIC_VECTOR(1 to N_OUTPUTS);\n\n');
fprintf(fid8,'BEGIN\n\n');
fprintf(fid8,'  ann0 : ann generic map ( N_INPUTS,\n');
fprintf(fid8,'                           N_HIDDEN,\n');
fprintf(fid8,'                           N_OUTPUTS\n');
fprintf(fid8,'             )\n');
fprintf(fid8,'             port map    ( new_input,\n');
fprintf(fid8,'                           ann_function,\n');
fprintf(fid8,'                           CLK,\n');
fprintf(fid8,'                           enable,\n');
fprintf(fid8,'                           ann_stop,\n');
fprintf(fid8,'                           ann_ready,\n');
fprintf(fid8,'                           ann_output\n');
fprintf(fid8,'            );\n\n');
fprintf(fid8,'PROCESS(CLK) IS \n\n');
fprintf(fid8,'  variable input_flag  : STD_LOGIC_VECTOR(1 to N_INPUTS) :=(others =>''0'');\n');
fprintf(fid8,'  variable flag        : STD_LOGIC := ''0'';\n');
fprintf(fid8,'  variable test_vector : STD_LOGIC_VECTOR(vector_length-1 downto 0);\n');
fprintf(fid8,'  variable LUT_decision: STD_LOGIC;\n\n');
fprintf(fid8,'BEGIN\n ');
fprintf(fid8,'  IF (CLK''EVENT AND CLK = ''%d'') THEN \n',CLK_STATE);
fprintf(fid8,'      CASE stage IS\n');
fprintf(fid8,'        WHEN read_input =>\n');
for i = 1:N_INPUTS
    fprintf(fid8,'          IF (hold_input.%s /= input.%s) THEN\n',input_map{i},input_map{i});
    fprintf(fid8,'            hold_input.%s <= input.%s;\n',input_map{i},input_map{i});
    fprintf(fid8,'            input_flag(%d)       := ''1'';\n',i);
    fprintf(fid8,'            CASE input.%s IS\n',input_map{i});
    for j = 1:size(normalized_list{i},1);
        fprintf(fid8,'              WHEN "%s"  => new_input.%s <= "%s";\n',binary_list{i,j},input_map{i},compressed_list{i,j});
    end;
    fprintf(fid8,'              WHEN others => NULL;\n');
    fprintf(fid8,'            END CASE;\n');
    fprintf(fid8,'          ELSE\n');
    fprintf(fid8,'            input_flag(%d)  := ''0'';\n',i);
    fprintf(fid8,'          END IF;\n');
end;

% Print switch criteria
if switch_enable ~= 1
    fprintf(fid8,'          flag := '); 
    for i = 1:N_INPUTS-1
        fprintf(fid8,'input_flag(%d) OR ',i);
    end;
    fprintf(fid8,'input_flag(%d);\n',N_INPUTS);
else
    fprintf(fid8,'          CASE reg_output IS\n');
    fprintf(fid8,'            -- In case of given switch criteria, bypass neural network\n');
    for i = 1:N_SCENARIOS
        fprintf(fid8,'            WHEN "%s" => %s\n',dec2bin(i,ceil(log2(N_SCENARIOS))),switch_criteria{i});
    end;
    fprintf(fid8,'            WHEN others => flag := ');
    for i = 1:N_INPUTS-1
        fprintf(fid8,'input_flag(%d) OR ',i);
    end;
    fprintf(fid8,'input_flag(%d);\n',N_INPUTS);
    fprintf(fid8,'          END CASE;\n');
end;

fprintf(fid8,'          IF (flag = ''1'') THEN\n');
fprintf(fid8,'            enable       <= ''1'';\n');
fprintf(fid8,'            ann_function <= run;\n');
fprintf(fid8,'            stage        <= correct;\n');
fprintf(fid8,'            output_flag  <= ''0'';\n');
fprintf(fid8,'          ELSE\n');
fprintf(fid8,'            enable       <= ''0'';\n');
fprintf(fid8,'            ann_function <= idle;\n');
fprintf(fid8,'            output_flag  <= ''1'';\n');
fprintf(fid8,'          END IF;\n');
fprintf(fid8,'        WHEN correct =>\n');
fprintf(fid8,'          LUT_decision := ''1'';\n');
fclose(fid8);


fprintf(fid9,'          IF (LUT_decision = ''1'') THEN \n');
fprintf(fid9,'            stage         <= drive_LUTS;\n');
fprintf(fid9,'            ann_stop      <= ''1'';\n');
fprintf(fid9,'          ELSE\n');
fprintf(fid9,'            ann_function  <= idle;\n');
fprintf(fid9,'            stage         <= drive_ann;\n');
fprintf(fid9,'          END IF;\n');
fprintf(fid9,'        WHEN drive_ann =>\n');
fprintf(fid9,'          IF (ann_ready = ''1'') THEN\n');
fprintf(fid9,'            output        <= ann_output;\n');
fprintf(fid9,'            reg_output    <= ann_output;\n');
fprintf(fid9,'            output_flag   <= ''1'';\n');
fprintf(fid9,'            enable        <= ''0'';\n');
fprintf(fid9,'            stage         <= read_input;\n');
fprintf(fid9,'          END IF;\n'); 
fprintf(fid9,'        WHEN drive_LUTS =>\n');
fprintf(fid9,'          output          <= LUT_output;\n');
fprintf(fid9,'          reg_output      <= LUT_output;\n');
fprintf(fid9,'          ann_stop        <= ''0'';\n');
fprintf(fid9,'          output_flag     <= ''1'';\n');
fprintf(fid9,'          enable          <= ''0'';\n');
fprintf(fid9,'          stage           <= read_input;\n');     
fprintf(fid9,'      END CASE;\n');
fprintf(fid9,'  END IF;\n');
fprintf(fid9,'END PROCESS;\n');
fprintf(fid9,'END ARCHITECTURE;');
fclose(fid9);



fprintf(fid10,'------------------------------------------------\n');
fprintf(fid10,'-- This final testbench has also 2 purposes:\n');
fprintf(fid10,'-- 1) Validation of proper function\n');
fprintf(fid10,'-- 2) Measurement of total Hardware cycles the \n');
fprintf(fid10,'--    design is going to need and comparison to\n');
fprintf(fid10,'--    the simple LUT implementation\n');
fprintf(fid10,'------------------------------------------------\n');
fprintf(fid10,'library ieee;\n');
fprintf(fid10,'library ieee_proposed;\n');
fprintf(fid10,'use ieee.std_logic_1164.ALL;\n');
fprintf(fid10,'use ieee.math_real.all;\n');
fprintf(fid10,'use work.neural_library.all;\n');
fprintf(fid10,'use ieee_proposed.fixed_pkg.all;\n');
fprintf(fid10,'use std.textio.all;\n\n');
fprintf(fid10,'ENTITY testbench_final IS\n');
fprintf(fid10,'END testbench_final;\n\n');
fprintf(fid10,'ARCHITECTURE behavior OF testbench_final IS\n\n');
fprintf(fid10,'    -- Component Declaration for the Unit Under Test (UUT)\n\n');
fprintf(fid10,'  COMPONENT hybrid IS\n');
fprintf(fid10,'    PORT (\n');
fprintf(fid10,'       input            : IN  input_vector;\n');
fprintf(fid10,'       CLK              : IN  STD_LOGIC;\n');
fprintf(fid10,'       output           : OUT STD_LOGIC_VECTOR(1 to N_OUTPUTS);\n');
fprintf(fid10,'       output_flag      : OUT STD_LOGIC\n');
fprintf(fid10,'    );\n');
fprintf(fid10,'  END COMPONENT;\n\n');
fprintf(fid10,'  type states IS (\n');
fprintf(fid10,'           first,\n');
fprintf(fid10,'			  second,\n');
fprintf(fid10,'			  third\n');
fprintf(fid10,'	      );\n\n');	
fprintf(fid10,'  -- signals\n\n');
fprintf(fid10,'  CONSTANT N_EXAMPLES       : integer := %d;                   -- This value must always meet the size of the dataset.\n',N_ROWS);
fprintf(fid10,'                                                               -- Change if using a different dataset\n');
fprintf(fid10,'  signal hybrid_input       : input_vector ;\n');
fprintf(fid10,'  signal hybrid_output      : STD_LOGIC_VECTOR(1 TO N_OUTPUTS);\n');
fprintf(fid10,'  signal hybrid_output_flag : STD_LOGIC;\n');
fprintf(fid10,'  signal test_output_signal : BIT_VECTOR(1 TO N_OUTPUTS);\n');
fprintf(fid10,'  signal CLK                : std_logic := ''0'';\n\n');
fprintf(fid10,'  signal wait_counter       : integer;\n');
fprintf(fid10,'  signal cycle_counter      : integer := 0;\n');
fprintf(fid10,'  signal num_cases          : integer := 0;\n');
fprintf(fid10,'  signal state              : states :=first;\n\n\n');
fprintf(fid10,'  -- Clock period definitions\n');
fprintf(fid10,'  constant CLK_period : time := 10 ns;\n\n');
fprintf(fid10,'  -- File definitions\n');
fprintf(fid10,'  FILE inputfile    : text OPEN read_mode  IS "%s";\n',strcat(CurrentFolder,'/inputs.txt'));        % Use CurrentFolder variable to reconstruct the folder path
fprintf(fid10,'  FILE outputfile   : text OPEN read_mode  IS "%s";\n',strcat(CurrentFolder,'/outputs.txt'));
fprintf(fid10,'  FILE reportfile   : text OPEN write_mode IS "%s";\n',strcat(CurrentFolder,'/report_metrics.txt'));

fprintf(fid10,'BEGIN\n\n');
fprintf(fid10,'  -- Instantiate the Unit Under Test (UUT\n');
fprintf(fid10,'  uut: hybrid PORT MAP (\n');
fprintf(fid10,'                input             => hybrid_input,\n');
fprintf(fid10,'                CLK               => CLK,\n');
fprintf(fid10,'                output            => hybrid_output,\n');
fprintf(fid10,'                output_flag       => hybrid_output_flag\n');
fprintf(fid10,'              );\n\n');
fprintf(fid10,'  -- Clock process definitions\n');
fprintf(fid10,'  CLK_process : process\n');
fprintf(fid10,'  begin\n');
fprintf(fid10,'    CLK <= ''0'';\n');
fprintf(fid10,'    wait for CLK_period/2;\n');
fprintf(fid10,'    CLK <= ''1'';\n');
fprintf(fid10,'    wait for CLK_period/2;\n');
fprintf(fid10,'  end process;\n\n');
fprintf(fid10,'read_input : process(CLK) IS\n\n');
fprintf(fid10,'  variable input_line     : line;\n');
fprintf(fid10,'  variable output_line    : line;\n');
fprintf(fid10,'  variable dataline       : line;\n');
fprintf(fid10,'  variable writer         : line;\n');
fprintf(fid10,'  variable new_line       : line;\n');
fprintf(fid10,'  variable test_input     : input_bitvector;\n');
fprintf(fid10,'  variable test_output    : BIT_VECTOR(1 TO N_OUTPUTS);\n\n');
fprintf(fid10,'BEGIN\n\n');
fprintf(fid10,'  IF (CLK''EVENT AND CLK = ''%d'') THEN\n',CLK_STATE);
fprintf(fid10,'    IF (wait_counter > 0) THEN\n');
fprintf(fid10,'      wait_counter <= wait_counter - 1;\n');
fprintf(fid10,'    ELSE\n');
fprintf(fid10,'      CASE state IS\n');
fprintf(fid10,'        WHEN first =>\n');
fprintf(fid10,'          readline(inputfile,input_line);\n');
for i =1:N_INPUTS
    fprintf(fid10,'          read(input_line,test_input.%s);\n',input_map{i});
    fprintf(fid10,'          hybrid_input.%s <= to_slv(test_input.%s);\n',input_map{i},input_map{i});
end;
fprintf(fid10,'          readline(outputfile,output_line);\n');
fprintf(fid10,'          for i IN 1 to N_OUTPUTS LOOP\n');
fprintf(fid10,'            read(output_line,test_output(i));\n');
fprintf(fid10,'            test_output_signal(i) <= test_output(i);\n');
fprintf(fid10,'          END LOOP;\n');
fprintf(fid10,'          wait_counter <=  1;\n');
fprintf(fid10,'          num_cases    <= num_cases + 1;\n');
fprintf(fid10,'          state        <= second;\n');
fprintf(fid10,'        WHEN second =>\n');
fprintf(fid10,'          IF (hybrid_output_flag = ''1'') THEN\n');
fprintf(fid10,'            cycle_counter <= cycle_counter + 1;\n');
fprintf(fid10,'            FOR i IN 1 to N_OUTPUTS LOOP\n');
fprintf(fid10,'              assert (test_output_signal(i) = to_bit(hybrid_output(i)))\n');
fprintf(fid10,'              report "Wrong Result in Output : " & integer''image(i) & " at input_vector: "&integer''image(num_cases);\n');
fprintf(fid10,'            END LOOP;\n');
fprintf(fid10,'            IF (num_cases = N_EXAMPLES) THEN\n');
fprintf(fid10,'              state <= third;\n');
fprintf(fid10,'            ELSE\n');
fprintf(fid10,'              state <= first;\n');
fprintf(fid10,'            END IF;\n');
fprintf(fid10,'          ELSE\n');
fprintf(fid10,'            cycle_counter <= cycle_counter + 1;\n');
fprintf(fid10,'          END IF;\n');
fprintf(fid10,'        WHEN third =>\n');  
fprintf(fid10,'          write(writer,"           |      Hybrid      |    Full_LUT");\n');
fprintf(fid10,'          writeline(reportfile,writer);\n');
fprintf(fid10,'          write(writer," -------------------------------------------------------- ");\n');
fprintf(fid10,'          writeline(reportfile,writer);\n');
fprintf(fid10,'          write(writer," HW Cycles |      ");\n');
fprintf(fid10,'          write(writer,cycle_counter);\n');
fprintf(fid10,'          write(writer,"       |     ");\n');
fprintf(fid10,'          write(writer,num_cases *2);\n');
fprintf(fid10,'          writeline(reportfile,writer);\n');
fprintf(fid10,'          report "END OF SIMULATION";\n');
fprintf(fid10,'          wait_counter <= 10000000;\n');
fprintf(fid10,'        END CASE;\n');
fprintf(fid10,'      END IF;\n');
fprintf(fid10,'  END IF;\n');
fprintf(fid10,'END PROCESS;\n\n');
fprintf(fid10,'END ARCHITECTURE;');
fclose(fid10);

