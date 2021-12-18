function [No_RTS, Rows, No_Outputs, No_Scenarios, initial_path, train_file] = load_and_read_train()

% This function is the first one called through the "buld_neural" GUI. It
% stores the initial directory Matlab uses, then asks for a file. This file 
% holds the training data that we are using for our Neural Networks. Function
% returns after completing a procession of this file, through which it calculates
% the basic attributes of the proposed Neural Network.

% Store initial Matlab path
initial_path         = pwd;

% Load dat file
[filename, pathname] = uigetfile({'*.dat'},'File Selector');  

% Store the full path of the file in this variable
file_path            = strcat(pathname,filename)  ;   

% Store the values within the data file in this matrix (train_file)
train_file           = load(file_path);    
cd(pathname);

% Calculate the main aspects of Neural Networks
Rows          = size(train_file,1);
Columns       = size(train_file,2);
No_RTS        = size(train_file,2)-1;

% Matrix instantiation   (It is common practice to instantiate arrays or
% matrixes in Matlab to allocate enough memory resources) 
Scenarios    = zeros(Rows,1);

% Seperate RTS data from Scenarios data
for i = 1: Rows
    Scenarios(i,1) = train_file(i, Columns);
end;


No_Outputs   = ceil(log2(max(Scenarios)));
No_Scenarios = length(unique(Scenarios));
