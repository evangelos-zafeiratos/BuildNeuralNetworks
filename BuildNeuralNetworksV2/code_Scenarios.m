function [bits,binary_list] = code_Scenarios(Scenario_list)

% This function takes a list of integer as input and  converts them 
% to their binary represenation. The element of highest value defines
% the number of bits of the representation. The function also prints a 
% text file (outputs.txt) which contains this list of binary values.
%
% Usage : [num_bits, list] = code_Scenarios(X), 
%         where X is an array of Integer.
  
% This file is needed for the stage of simulation
FileID = fopen('outputs.txt','w');

% Create a cell structure to store the binary values of Scenarios
coded_Scenario_list = cell(size(Scenario_list,1),1);

% Calculation of number of bits to be used
if log2(max(Scenario_list)) == ceil(log2(max(Scenario_list)))
    bits = ceil(log2(max(Scenario_list))) + 1;
else
    bits = ceil(log2(max(Scenario_list)));
end;

% Converts each value into binary form and stores it in the cell.
for i = 1:size(Scenario_list,1)
    coded_Scenario_list{i} = dec2bin(Scenario_list(i),bits);
end;

% Prints output values
binary_list = zeros(size(Scenario_list,bits));
for i = 1:size(Scenario_list,1)
    for j = 1:bits
        binary_list(i,j) = str2double(coded_Scenario_list{i}(j));
        fprintf(FileID,'%d     ',binary_list(i,j));
    end;
   fprintf(FileID,'\n');
end;
        
fclose(FileID);
clear FileID;
clear coded_Scenario_list;