clear;
clc;
load('analysis.mat')

for j = 2:2500
    i=1;
    if y1_norm(j,1,i) == y1_norm(j-1,1,i)
        t1_norm(j,1,i) = t1_norm(j-1,1,i);
    end
    if y2_norm(j,1,i) == y2_norm(j-1,1,i)
        t2_norm(j,1,i) = t2_norm(j-1,1,i);
    end
    if y3_norm(j,1,i) == y3_norm(j-1,1,i)
        t3_norm(j,1,i) = t3_norm(j-1,1,i);
    end
    if y4_norm(j,1,i) == y4_norm(j-1,1,i)
        t4_norm(j,1,i) = t4_norm(j-1,1,i);
    end
    if y5_norm(j,1,i) == y5_norm(j-1,1,i)
        t5_norm(j,1,i) = t5_norm(j-1,1,i);
    end
end

hold on
plot(t1_norm, y1_norm, '.');
plot(t2_norm, y2_norm, '.');
plot(t3_norm, y3_norm, '.');
plot(t4_norm, y4_norm, '.');
plot(t5_norm, y5_norm, '.');

yave = [y1_norm; y2_norm; y3_norm; y4_norm; y5_norm];
tave = [t1_norm; t2_norm; t3_norm; t4_norm; t5_norm];
combined = [tave yave];
combined = sortrows(combined,1);

load('C:\Users\Jacob\Documents\Senior\IDEAlab\datas\Pullup Sim\analysis.mat')
%plot_exper(d075_12);

t_max = max(tss_norm(:,1,1));
extra = 0.1;
within_time = combined(combined(:,1) < (t_max + extra), :);
average = movmean(within_time, 24);

plot(average(:,1), average(:,2), '-');
title('075-12');
