function [Rows, val_file] = load_and_read_validation()

% This function asks for a dat file. That file holds the validation data
% used for our Neural Network. Returns after calclulating exact number of 
% RTS.

% Load dat file 
[filename, pathname] = uigetfile({'*.dat'},'File Selector'); 

% Store the full path of the file in this variable 
file_path            = strcat(pathname,filename);  

 % Store the values within the data file in this matrix (val_file)
val_file             = load(file_path);                     
Rows                 = size(val_file,1);

