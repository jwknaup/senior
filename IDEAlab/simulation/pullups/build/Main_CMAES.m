% In The Name OF GOD
clc
clear all
close all
% mkdir('Second_Run')
% cd 'Second_Run'
global feasibles in_history out_history set_number  Exper_Data4 Exper_Data8 Exper_Data12 %cal_fx cal_fy cal_fz cal_mx cal_my cal_mz

set_number = 1;

%%%%%%%%%%%%%%%       Running Modified CMA-ES       %%%%%%%%%%%%%%%

load('Exper_Data4.mat')
load('Exper_Data8.mat')
load('Exper_Data12.mat')
% Exper_data = average(any(average,2),:);

cmaes_Jacob
% 
% x=[30.2174  -54.3369];
% y = MyCost_Min_Radius(x)

save('In_H.mat','in_history');
save('Out_H.mat','out_history');
save('Cost_H.mat','BestCost');
Best_Sol_Value = BestSol.Position;
save('Best_Sol.mat','BestSol');

[min_val,min_n] = min(out_history)