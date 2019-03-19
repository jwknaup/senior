function [y] = MyCost_Max_Thrust(x)
global in_history out_history set_number Exper_Data4 Exper_Data8 Exper_Data12
x1 = x(1);
<<<<<<< HEAD
x2 = x(2);
x3 = x(3);
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
commandStr = ['"C:\Users\Jacob\Documents\Senior\IDEAlab\simulation\pullups\build\pullups.exe" ','-batchmode',' ',num2str(x1),' ',num2str(x2),' ',num2str(x3),' ',num2str(x4),' ',num2str(x5),' ',num2str(x6), ' 4'];
=======
% x2 = x(2);
% x3 = x(3);
% x4 = x(4);
% x5 = x(5);
% x6 = x(6);
% x7 = x(7);
% x8 = x(8);
% x9 = x(9);
% x10 = x(10);
% x11 = x(11);
% x12 = x(12);

% -batchmode
commandStr = ['"C:\Users\Jacob\Documents\Senior\IDEAlab\simulation\pullups\build\pullups.exe" ','-batchmode',' ',num2str(x1),' 0.04'];
>>>>>>> adf5cc6... new
[status, commandOut] = system(commandStr);
if status==0
    Sim_Data = xlsread('output.csv');
%     fprintf('squared result is %d\n',str2double(commandOut));
else
    disp('BAD STATUS');
    Sim_Data = [0 0];
end
y = Vector_Time_Diff(Exper_Data4,Sim_Data);


<<<<<<< HEAD
commandStr = ['"C:\Users\Jacob\Documents\Senior\IDEAlab\simulation\pullups\build\pullups.exe" ','-batchmode',' ',num2str(x1),' ',num2str(x7),' ',num2str(x8),' ',num2str(x9),' ',num2str(x5),' ',num2str(x6), ' 8'];
=======
commandStr = ['"C:\Users\Jacob\Documents\Senior\IDEAlab\simulation\pullups\build\pullups.exe" ','-batchmode',' ',num2str(x1),' 0.08'];
>>>>>>> adf5cc6... new
[status, commandOut] = system(commandStr);
if status==0
    Sim_Data = xlsread('output.csv');
%     fprintf('squared result is %d\n',str2double(commandOut));
else
    disp('BAD STATUS');
    Sim_Data = [0 0];
end
<<<<<<< HEAD
y = y + Vector_Time_Diff(Exper_Data8,Sim_Data);


commandStr = ['"C:\Users\Jacob\Documents\Senior\IDEAlab\simulation\pullups\build\pullups.exe" ','-batchmode',' ',num2str(x1),' ',num2str(x10),' ',num2str(x11),' ',num2str(x12),' ',num2str(x5),' ',num2str(x6), ' 12'];
=======
y = y+Vector_Time_Diff(Exper_Data8,Sim_Data);


commandStr = ['"C:\Users\Jacob\Documents\Senior\IDEAlab\simulation\pullups\build\pullups.exe" ','-batchmode',' ',num2str(x1), ' 0.12'];
>>>>>>> adf5cc6... new
[status, commandOut] = system(commandStr);
if status==0
    Sim_Data = xlsread('output.csv');
%     fprintf('squared result is %d\n',str2double(commandOut));
else
    disp('BAD STATUS');
    Sim_Data = [0 0];
end
<<<<<<< HEAD
y = y + Vector_Time_Diff(Exper_Data12,Sim_Data)
=======
y = y+Vector_Time_Diff(Exper_Data12,Sim_Data);
>>>>>>> adf5cc6... new

%     disp(x);
in_history(set_number,:) = x;
out_history(set_number,:) = y;
set_number = set_number +1;

save('In_H.mat','in_history');
save('Out_H.mat','out_history');

end
