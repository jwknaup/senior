function [y4 y8 y12] = MyCost_Max_Thrust(x)
global in_history out_history set_number Exper_Data
x1 = x(1);
x2 = x(2);
x3 = x(3);
<<<<<<< HEAD
x4 = x(4);
x5 = x(5);
x6 = x(6);
x7 = x(7);
x8 = x(8);
x9 = x(9);
x10 = x(10);
x11 = x(11);
x12 = x(12);

% -batchmode
commandStr = ['"./pullups.exe" ','-0',' ',num2str(x1),' ',num2str(x2),' ',num2str(x3),' ',num2str(x4),' ',num2str(x5),' ',num2str(x6), ' 4'];
=======

% -batchmode
commandStr = ['"./pullups.exe" ','-0',' ',num2str(x1),' 0.04', ' 75'];
>>>>>>> adf5cc6... new
[status, commandOut] = system(commandStr);
if status==0
    Sim_Data = csvread('output.csv');
%     fprintf('squared result is %d\n',str2double(commandOut));
else
    disp('BAD STATUS');
    Sim_Data = [0 0];
end
<<<<<<< HEAD
y4 = Sim_Data


commandStr = ['"./pullups.exe" ','-0',' ',num2str(x1),' ',num2str(x7),' ',num2str(x8),' ',num2str(x9),' ',num2str(x5),' ',num2str(x6), ' 8'];
=======
y4 = Sim_Data;


commandStr = ['"./pullups.exe" ','-0',' ',num2str(x2),' 0.08', ' 75'];
>>>>>>> adf5cc6... new
[status, commandOut] = system(commandStr);
if status==0
    Sim_Data = csvread('output.csv');
%     fprintf('squared result is %d\n',str2double(commandOut));
else
    disp('BAD STATUS');
    Sim_Data = [0 0];
end
<<<<<<< HEAD
y8 = Sim_Data


commandStr = ['"./pullups.exe" ','-0',' ',num2str(x1),' ',num2str(x10),' ',num2str(x11),' ',num2str(x12),' ',num2str(x5),' ',num2str(x6), ' 12'];
=======
y8 = Sim_Data;


commandStr = ['"./pullups.exe" ','-0',' ',num2str(x3),' 0.12', ' 75'];
>>>>>>> adf5cc6... new
[status, commandOut] = system(commandStr);
if status==0
    Sim_Data = csvread('output.csv');
%     fprintf('squared result is %d\n',str2double(commandOut));
else
    disp('BAD STATUS');
    Sim_Data = [0 0];
end
<<<<<<< HEAD
y12 = Sim_Data
=======
y12 = Sim_Data;
>>>>>>> adf5cc6... new

end
