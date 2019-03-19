hold on
x1 = 0;
gears = [50 75 100 150 210 250 298 1000];
lengths = [0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 ]; 

labels = [];
maxes = [];
i=1;

results = zeros(size(gears,2)*size(lengths,2), 3);

for g = gears
    for l = lengths

        commandStr = ['"./pullups.exe" ','-batchmode',' ',num2str(x1),' ',num2str(l),' ',num2str(g)];
        [status, commandOut] = system(commandStr);
        if status==0
            Sim_Data = csvread('output.csv');
        %     fprintf('squared result is %d\n',str2double(commandOut));
        else
            disp('BAD STATUS');
            Sim_Data = [0 0];
        end
        y = Sim_Data;
        rel_height = 1/((max(y(:,2)))/(2*l));
        gnd_clearance = 1/(max(y(:,2))-l*2);
        plot(rel_height, gnd_clearance, 'o');
        text(rel_height, gnd_clearance, [num2str(g), ', ', num2str(l)]);
        labels(i) = g+l;
        
        disp(['gear ratio: ', num2str(g), ' length: ', num2str(l), ' max: ' num2str(max(y(:,2))), ' jump: ' num2str(max(y(:,2))-l*2)])
        results(i,:) = [g, l*100, max(y(:,2))-l*2];
        
        i=i+1;
    end
end

%csvwrite('unity_results.csv', results);