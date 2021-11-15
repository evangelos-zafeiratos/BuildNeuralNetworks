function [] = print_no_training_values(RTS, Scenarios, bad_data)


FileID                  = fopen('no_training.dat','w');

for i = 1: size(bad_data,2)
    for j = 1: size(RTS,2)
        temp = RTS(bad_data{i},j);
        fprintf(FileID,'%d',temp);
        fprintf(FileID,';');
    end;
     temp = Scenarios(bad_data{i},1);
     fprintf(FileID,'%d',temp);
     fprintf(FileID,'\n');
end;

fclose(FileID);