function [NewRTS, normalized_unique_list, binary_RTS, compressed_binary_RTS, bits_for_RTS, bits_for_compressed_RTS, mean_value, std_dev ] = code_inputs(RTS_list)
%
% This function takes as an input a matrix, in which every column stands for
% a set of values and produces for every column input a normalized column output
% in the range [-1,1]. The function also prints a .txt file with the inputs
% in binary form, that is going to used for Simulation purposes.
%


  Rows                    = size(RTS_list,1);
  Columns                 = size(RTS_list,2);
  NewRTS                  = zeros(Rows,Columns);
  unique_list             = cell(Columns,1);
  normalized_unique_list  = cell(Columns,1);
  FileID                  = fopen('inputs.txt','w');
  
  % Creating lists with the unique values for every RTS variable
  list_length             = zeros(1,Columns);
  max_element             = zeros(1,Columns);
  bits_for_RTS            = zeros(1,Columns);
  bits_for_compressed_RTS = zeros(1,Columns);
  mean_value              = zeros(1,Columns);
  std_dev                 = zeros(1,Columns);
  
  
  for i = 1: Columns
      unique_list{i}             = unique(RTS_list(:,i));
      list_length(i)             = length(unique_list{i});
      max_element(i)             = max(unique_list{i});
      if  log2(max_element(i)) == ceil(log2(max_element(i)))  %max_element(i) == list_length(i)  
          bits_for_RTS(i)        = ceil(log2(max_element(i))) + 1;
      else 
          bits_for_RTS(i)        = ceil(log2(max_element(i)));
      end;
      bits_for_compressed_RTS(i) = ceil(log2(list_length(i)));
  end;
  
  max_list              = max(list_length);
  binary_RTS            = cell(Columns, max_list);
  compressed_binary_RTS = cell(Columns, max_list);
  
  % Putting into final_list the unique values of input
   for i = 1:Columns
      for j = 1:list_length(i)
          temp1 = dec2bin(unique_list{i}(j),bits_for_RTS(i));
          binary_RTS{i,j} = temp1;
      end;
  end;
  for i = 1:Columns
      for j = 1:list_length(i)
          compressed_binary_RTS{i,j} = dec2bin(j-1,bits_for_compressed_RTS(i));
      end;
  end;
 
          
  
  % Here print the binary values of RTS table
  for i = 1:Rows
      for j = 1:Columns
          temp2 = dec2bin(RTS_list(i,j),bits_for_RTS(j));
          fprintf(FileID,'%s     ',temp2);
      end;
      fprintf(FileID,'\n');
  end;
 

 for i = 1:Columns
     mean_value(i)      = mean(RTS_list(:,i));
     NewRTS(:,i)        = RTS_list(:,i) - mean_value(i);
     std_dev(i)         = std(NewRTS(:,i),1);
     NewRTS(:,i)        = NewRTS(:,i)/(std_dev(i)/0.75);    
 end;
 
 for i = 1:Columns
     normalized_unique_list{i} = unique(NewRTS(:,i));
 end;

fclose(FileID);