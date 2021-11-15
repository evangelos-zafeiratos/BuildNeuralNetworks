function [] = train_and_print(structure)

% This function uses all the data stored from the user in the GUI,
% processes them, and trains a Neural Networks with specific attributes.
% Afterwards, depending on the choices of user, prints the suitable files 
% needed to form the entire Neural Network, along with Testbenches, which
% allows the user to validate its accuracy.
% 
%--------------------------------------------------------------------------
% Troubleshooting 
%--------------------------------------------------------------------------
%
% 1) The training algorithm described in this function (see net.trainFcn)is
%    "Levenberg - Marquadt" algorithm, which requires a significant amount of
%    memory resources. In case of training large Networks, it is not an
%    optimal solution. Alternatively, you should try either "Scaled
%    Conjugate Gradient" or "Resilient Backpropagation". The commands for
%    these algorithms are "trainscg" and "trainrp" respectively.
% 2) There is also a memory constraint regarding  the size of arrays that
%    Matlab is allowed to use at a specific time. In case of getting memory
%    errors, you should add in the training command :
%    "[net,tr] = train(net,input,output)" the phrase "memory_reduction,n"
%    where n is the divisor. As in the example below :
%    [net,tr] = train(net,input,output,'reduction',2);


% Processing user input
full_matrix     = structure.dataset;
No_train_enable = structure.No_train_enable;

if No_train_enable == 1
    No_train_values = structure.No_training;
end;

hidden_nodes    = structure.hidden_nodes;
matlab_path     = structure.original_path;

Rows            = size(full_matrix,1);
Columns         = size(full_matrix,2);
switch_criteria = structure.switch_criteria;
switch_enable   = structure.enable_criteria;

% Training Parameters
numNN           = structure.instances;


% Store a Numeric Value to calculate Precision
switch strtrim(structure.precision)          % Use strtrim function to remove unnecessary blanks from the string 
    case 'Low'
        accuracy = 0;
    case 'Medium'
        accuracy = 1;
    case 'High'
        accuracy = 2;
    case 'Very High'
        accuracy = 3;
    otherwise
        accuracy = 1;
end;

% Store a numeric Value for Clk Triggering variable
switch strtrim(structure.CLK)
    case 'Rising Edge'
        trigger_CLK = 1;
    case 'Falling Edge'
        trigger_CLK = 0;
    otherwise
        trigger_CLK = 1;
end;

% Store a numeric value for activation function selection
switch strtrim(structure.act_function)
    case 'Normal'
        activation_function = 0;
    case 'Extended'
        activation_function = 1;
    otherwise
        activation_function = 0;
end;

switch strtrim(structure.mul_style)
    case 'LUTs'
        multiplier_style = 0;
    case 'Multipliers'
        multiplier_style = 1;
    otherwise
        multiplier_style = 0;
end;

switch strtrim(structure.LUT_select)
    case 'Multiple'
        LUT_selection = 0;
    case 'Single'
        LUT_selection = 1;
    otherwise
        LUT_selection = 1;
end;

% Matrix instantiation   (It is common practice to instantiate arrays or
% matrixes in Matlab to allocate enough memory resources) 
RTS       = zeros(Rows,Columns-1);
Scenarios = zeros(Rows,1);

% Seperate RTS data from Scenarios data
for i = 1: Rows
    for j = 1: Columns-1
        RTS(i,j) = full_matrix(i,j);
    end;
    Scenarios(i,1) = full_matrix(i, Columns);
end;

% Normalization of RTS and Scenario values  
[~ , Scenario_binary ]                                                                                                 = code_Scenarios(Scenarios);
[RTS_matrix, normalized_list, binary_list, compressed_list, binary_bits, compressed_RTS_bits, mean_value, std_dev ]    = code_inputs(RTS);


% Exclude specific values from training, only if a suitable file is given.
% This attribute is acceptable only if a single LUT architecture has been
% chosen. Otherwise, the selected values will be trained.
if ( No_train_enable == 1 && LUT_selection == 1)
    common_indices     = ismember(full_matrix,No_train_values,'Rows');
    RTS_matrix         = removerows(RTS_matrix,common_indices);
    Scenario_binary    = removerows(Scenario_binary,common_indices);
    indices            = find(common_indices);
    Train_rows         = structure.Train_rows - length(indices);
    Val_rows           = structure.Val_rows;
    Total_rows         = Train_rows + Val_rows;
    Train_ratio        = Train_rows/Total_rows;
    Val_ratio          = Val_rows/Total_rows;
else
    indices            =  0 ;
    Train_rows         = structure.Train_rows;
    Val_rows           = structure.Val_rows;
    Total_rows         = Train_rows + Val_rows;
    Train_ratio        = Train_rows/Total_rows;
    Val_ratio          = Val_rows/Total_rows;
end;


  
% Initial performance set by user. Performance corresponds to the value of
% mean squared error, which is the most commonly used performance index for
% Neural Networks. 

net                        = feedforwardnet(hidden_nodes);
nets                       = cell(1,numNN);
tr                         = cell(1,numNN);
performance                = zeros(1,numNN);
input                      = RTS_matrix';
output                     = Scenario_binary';
net.divideFcn              = 'divideblock';
net.divideParam.trainRatio = Train_ratio;
if Val_ratio > 0
    net.divideParam.valRatio   = Val_ratio;
else
    net.divideParam.valRatio   = 0;
end;
net.divideParam.testRatio  = 0;
net.layers{1}.transferFcn  = 'logsig';                    % Choose Activation Function for hidden layer
net.layers{2}.transferFcn  = 'logsig';                    % Choose Activation Function for output layer
% -------------------------------------------
% This parameter is subject to change if
% the network under training is significantly
% large. Other options are "trainscg" and 
% "trainrp"
net.trainFcn               = 'trainlm';
% -------------------------------------------
net.trainParam.epochs      = 10000;                        % Teriminate after specific number of dataset iterations 
net.trainParam.max_fail    = 10;                    % Terminate training after 6 consecutive increase in validation set mse(mean squared error)
net.inputs{1}.processFcns  = {};
net.outputs{2}.processFcns = {};
net.trainParam.min_grad    = 0.00000000000000000000001;   % Terminate training when grad(mse) reaches that limit
net = init(net);

% --------------------------------------------------------------------------
% Every training is different due to different initial weights 
% and biases, which are randomly selected, so we choose to train
% several times and to keep the iteration with best results.
for i = 1:numNN                                          
    [nets{i},tr{i}] = train(net,input,output,'reduction',2);
    performance(i)  = tr{i}.best_perf;
end;
% --------------------------------------------------------------------------

[best_performance,I ] = min(performance);
chosen_net     = nets{I};

best_performance
counter = 0;
bad_data = {};
new_input  = input';
new_output = output';
evaluation = chosen_net(input);    % Evaluate Neural Network
for i = 1: size(output,2)
    for j = 1: size(output,1)
        if abs(evaluation(j,i) - output(j,i) > 0.03)  % For error greater than this value (0.1) remove from next training
            new_input = removerows(new_input,i - counter); 
            new_output = removerows(new_output,i - counter);
            Train_rows = Train_rows - 1;
            bad_data{end+1} = i;
            counter = counter + 1;
            break;
        end;
    end;
end;
 
if No_train_enable ~= 0
    print_no_training_values(RTS, Scenarios, bad_data);
end;

% bad_data
% input = new_input';
% output = new_output';
% Train_ratio        = Train_rows/Total_rows;
% Val_ratio          = Val_rows/Total_rows;
% net.divideParam.trainRatio = Train_ratio;
% if Val_ratio > 0
%     net.divideParam.valRatio   = Val_ratio;
% else
%     net.divideParam.valRatio   = 0;
% end;
% net = init(net);
% for i = 1:numNN                                          
%     [nets{i},tr{i}] = train(net,input,output,'reduction',2);
%     performance(i)  = tr{i}.best_perf;
% end;
% 
% 
% [best_performance,I ] = min(performance);
% chosen_net     = nets{I};
% best_performance

clear nets;
clear tr;

% Print Libraries
mkdir('Library');
File1 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Library/fixed_pkg_c.vhdl');
File2 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Library/fixed_float_types_c.vhdl');
copyfile(File1,strcat(pwd,'/Library'),'f');
copyfile(File2,strcat(pwd,'/Library'),'f');

% Architecture with multiple LUTs is selected
if (LUT_selection == 0 )

    % Print Templates
    if (trigger_CLK == 0) && (activation_function == 0)
        File1 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Templates/log_sigmoid_f_CLK.vhd');
        File2 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Templates/ann_f_CLK.vhd');
            else if (trigger_CLK == 0) && (activation_function == 1)
                File1 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Templates/log_sigmoid_extended_f_CLK.vhd');
                File2 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Templates/ann_f_CLK.vhd');
                else if (trigger_CLK == 1) && (activation_function == 0)
                    File1 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Templates/log_sigmoid.vhd');
                    File2 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Templates/ann.vhd');
                    else if (trigger_CLK == 1) && (activation_function == 1)
                        File1 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Templates/log_sigmoid_extended.vhd');
                        File2 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Templates/ann.vhd');
                        end;
                    end;
                end;
    end;
    
    mkdir('Templates');
    copyfile(File1,strcat(pwd,'/Templates'),'f');
    copyfile(File2,strcat(pwd,'/Templates'),'f');

   % Calling  the functions that print VHDL files
    if (multiplier_style == 0)
        print_VHDL_LUTs(chosen_net, normalized_list, binary_list, compressed_list, Rows, accuracy,...
                        binary_bits, compressed_RTS_bits, mean_value, std_dev ,trigger_CLK,...
                        switch_criteria, switch_enable);
    else if (multiplier_style == 1)
        print_VHDL_multipliers(chosen_net, normalized_list, binary_list, compressed_list, Rows, accuracy,...
                               binary_bits, compressed_RTS_bits, mean_value, std_dev ,trigger_CLK,...
                               switch_criteria, switch_enable);
        end;
    end;

% Architecture with single LUT is selected
else if (LUT_selection == 1)
        
        % Print Templates
        if (trigger_CLK == 0) && (activation_function == 0)
            File1 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Templates/log_sigmoid_f_CLK.vhd');
            File2 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Templates/ann_singleLUT_f.vhd');
            else if (trigger_CLK == 0) && (activation_function == 1)
                File1 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Templates/log_sigmoid_extended_f_CLK.vhd');
                File2 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Templates/ann_singleLUT_f.vhd');
                else if (trigger_CLK == 1) && (activation_function == 0)
                    File1 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Templates/log_sigmoid.vhd');
                    File2 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Templates/ann_singleLUT.vhd');
                    else if (trigger_CLK == 1) && (activation_function == 1)
                        File1 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Templates/log_sigmoid_extended.vhd');
                        File2 = strcat(matlab_path,'/Apps/BuildNeuralNetworksV2/Templates/ann_singleLUT.vhd');
                        end;
                    end;
                end;
        end;
   
    mkdir('Templates');
    copyfile(File1,strcat(pwd,'/Templates'),'f');
    copyfile(File2,strcat(pwd,'/Templates'),'f');
    
    % Calling  the functions that print VHDL files
    if (multiplier_style == 0)
        print_VHDL_LUTs_singleLUT(chosen_net, normalized_list, binary_list, compressed_list, Rows, accuracy,...
                   binary_bits, compressed_RTS_bits, mean_value, std_dev ,trigger_CLK,...
                   switch_criteria, switch_enable,No_train_enable, indices);
    else if (multiplier_style == 1)
        print_VHDL_multipliers_singleLUT(chosen_net, normalized_list, binary_list, compressed_list, Rows, accuracy,...
                   binary_bits, compressed_RTS_bits, mean_value, std_dev ,trigger_CLK,...
                   switch_criteria, switch_enable,No_train_enable, indices);
         end;
    end;

    end;
end;
cd(matlab_path);
