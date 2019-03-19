function [y4 y8 y12] = MyCost_Max_Thrust(x)
global in_history out_history set_number Exper_Data
x1 = x(1);
x2 = x(2);
x3 = x(3);

% -batchmode
commandStr = ['"./pullups.exe" ','-0',' ',num2str(x1),' 0.04', ' 75'];
[status, commandOut] = system(commandStr);
if status==0
    Sim_Data = csvread('output.csv');
%     fprintf('squared result is %d\n',str2double(commandOut));
else
    disp('BAD STATUS');
    Sim_Data = [0 0];
end
y4 = Sim_Data;


commandStr = ['"./pullups.exe" ','-0',' ',num2str(x2),' 0.08', ' 75'];
[status, commandOut] = system(commandStr);
if status==0
    Sim_Data = csvread('output.csv');
%     fprintf('squared result is %d\n',str2double(commandOut));
else
    disp('BAD STATUS');
    Sim_Data = [0 0];
end
y8 = Sim_Data;


commandStr = ['"./pullups.exe" ','-0',' ',num2str(x3),' 0.12', ' 75'];
[status, commandOut] = system(commandStr);
if status==0
    Sim_Data = csvread('output.csv');
%     fprintf('squared result is %d\n',str2double(commandOut));
else
    disp('BAD STATUS');
    Sim_Data = [0 0];
end
y12 = Sim_Data;

end
