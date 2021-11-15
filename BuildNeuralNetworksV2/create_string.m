function [switch_string] = create_string(file,No_Scenarios)

% Input file of this function determines the relationships among inputs
% that do not trigger a change of Scenario. These conditions given with '1's and
% '0's are translated in VHDL language using a simple algorithm, then stored
% as a string type and sent to the "print_VHDL" functions.
%
% Usage :  [string_variable ] = create_string(x,y)

Rows          = size(file,1);
Columns       = size(file,2);

line          = 1;
k             = 1;
switch_string = cell(No_Scenarios,1);      % Cell variable that stores the strings which determine the non-switch Criteria

while line < Rows                          % Line holds the Position within the .dat file
    
    No_conditions = file(line,1);
    one_elements  = zeros(1,No_conditions);
    for i=1:No_conditions
        one_elements(i) = sum(file(line+i,:));
    end;

    % Evaluate switch_string
    switch_string{k} = 'flag := ';        

    
    for i = 1:No_conditions
        switch_string{k} = strcat(switch_string{k},' ( ');
        for j = 1:Columns
            if file(line+i,j) == 1 &&  one_elements(i) ~= 1
                one_elements(i) = one_elements(i) - 1;
                switch_string{k} = strcat(strcat(strcat(switch_string{k},' input_flag('),num2str(j)),') OR');
            else if file(line+i,j) == 1 && one_elements(i) == 1
                    switch_string{k} = strcat(strcat(strcat(switch_string{k},' input_flag('),num2str(j)),'))');
                 end;
            end;
        end;
        if i < No_conditions
            switch_string{k} = strcat(switch_string{k},'  AND ');  % Use of AND To exclude all these cases from changing the Scenario
        end;
    end;
    switch_string{k} = strcat(switch_string{k},';');
    k                = k + 1;
    line             = line + No_conditions + 1;
end;
          
