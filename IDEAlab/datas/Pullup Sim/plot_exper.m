function plot_exper(dataset)
    dss(:,:,1) = dataset;
    dss(:,:,2) = dataset;
    % ds(:,:,3) = d3;
    % ds(:,:,4) = d4;
    % ds(:,:,5) = d5;
    % ds(:,:,6) = d6;
    % ds(:,:,7) = d7;
    % ds(:,:,8) = d8;
    % ds(:,:,9) = d9;
    % ds(:,:,10) = d0;

    tss = dss(:,1,:);
    yss = dss(:,2,:);

    startss = [1 1];% start3 start4 start5 start6 start7 start8 start9 start0];

    tss_norm = zeros(5000,1,10);
    yss_norm = zeros(5000,1,10);
    hold on
    for i = 1:1
        tss_norm(1:size(dss, 1),:,i) = tss(startss(i):end,:,i) - tss(startss(i),1,i);
        yss_norm(1:size(dss, 1),:,i) = yss(startss(i):end,:,i) - yss(startss(i),1,i);
        plot(tss_norm(:,1,i), -1/100*yss_norm(:,1,i), 'k.')
    end

end
    