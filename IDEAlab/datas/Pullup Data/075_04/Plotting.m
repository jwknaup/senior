clear;
clc;
load('analysis.mat')

ds(:,:,1) = d1;
ds(:,:,2) = d2;
ds(:,:,3) = d3;
ds(:,:,4) = d4;
ds(:,:,5) = d5;
ds(:,:,6) = d6;
ds(:,:,7) = d7;
ds(:,:,8) = d8;
ds(:,:,9) = d9;
ds(:,:,10) = d0;

ts = ds(:,1,:);
ys = ds(:,6,:);

starts = [start1 start2 start3 start4 start5 start6 start7 start8 start9 start0];

ts_norm = zeros(5000,1,10);
ys_norm = zeros(5000,1,10);
yave = zeros(1,1);
tave = zeros(1,1);
hold on
for i = 1:10
    ts_norm(1:5000-starts(i)+1,:,i) = ts(starts(i):end,:,i) - ts(starts(i),1,i);
    ys_norm(1:5000-starts(i)+1,:,i) = ys(starts(i):end,:,i) - ys(starts(i),1,i);
    for j = 2:5000
        if ys_norm(j,1,i) == ys_norm(j-1,1,i)
            ts_norm(j,1,i) = 0;
            ys_norm(j,1,i) = 0;
        end
    end
    if ~ismember(i,[2 5 10 9])
        yave = [yave; ys_norm(:,1,i)];
        tave = [tave; ts_norm(:,1,i)];
        plot(ts_norm(:,1,i), ys_norm(:,1,i), '.')
    end
end

combined = [tave yave];
combined = sortrows(combined,1);

load('C:\Users\Jacob\Documents\Senior\IDEAlab\datas\Pullup Sim\analysis.mat')
%plot_exper(d075_04);

t_max = max(tss_norm(:,1,1));
extra = 0.05;
within_time = combined(combined(:,1) < (t_max + extra), :);
average = movmean(within_time, 24);

plot(average(:,1), average(:,2), '-');
title('075-04');