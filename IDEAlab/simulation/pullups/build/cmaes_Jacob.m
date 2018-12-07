% clc;
% clear;
% close all;

global in_history out_history set_number fname %cal_fx cal_fy cal_fz cal_mx cal_my cal_mz

%% Problem Settings

% CostFunction=@SemiSphere;   % Cost Function
CostFunction=@MyCost;   % Cost Function
in111 = in_history;
out111 = out_history;
nVar=12;                % Number of Unknown (Decision) Variables

VarSize=[1 nVar];       % Decision Variables Matrix Size


%-- Uniform Variables

VarMin = [ 0 0 0 0 0 0 0 0 0 0 0 0];             % Lower Bound of Decision Variables
VarMax = [ 100 100 1000000 100000 10000 1000 100 1000000 100000 100 1000000 100000];             % Upper Bound of Decision Variables


%% CMA-ES Settings

% Maximum Number of Iterations
MaxIt=1000;


% Population Size (and Number of Offsprings)
% lambda=(4+round(3*log(nVar)))*10;
% lambda=nVar*10;
lambda = (4+round(3*log(nVar)))*10;
% Number of Parents
mu=round(lambda/2);

% Parent Weights
w=log(mu+0.5)-log(1:mu);
w=w/sum(w);

% Number of Effective Solutions
mu_eff=1/sum(w.^2);

% Step Size Control Parameters (c_sigma and d_sigma);
sigma0=0.3*(VarMax-VarMin);
cs=(mu_eff+2)/(nVar+mu_eff+5);
ds=1+cs+2*max(sqrt((mu_eff-1)/(nVar+1))-1,0);
ENN=sqrt(nVar)*(1-1/(4*nVar)+1/(21*nVar^2));

% Covariance Update Parameters
cc=(4+mu_eff/nVar)/(4+nVar+2*mu_eff/nVar);
c1=2/((nVar+1.3)^2+mu_eff);
alpha_mu=2;
cmu=min(1-c1,alpha_mu*(mu_eff-2+1/mu_eff)/((nVar+2)^2+alpha_mu*mu_eff/2));
hth=(1.4+2/(nVar+1))*ENN;

%% Initialization

ps=cell(MaxIt,1);
pc=cell(MaxIt,1);
C=cell(MaxIt,1);
sigma=cell(MaxIt,1);

ps{1}=zeros(VarSize);
pc{1}=zeros(VarSize);
C{1}=eye(nVar);
sigma{1}=sigma0;

empty_individual.Position=[];
empty_individual.Step=[];
empty_individual.Cost=[];

M=repmat(empty_individual,MaxIt,1);
Sol = unifrnd(VarMin,VarMax,VarSize);

%--- Feasibility Check
% while Isfeasible(Sol)==0
%     Sol = unifrnd(VarMin,VarMax,VarSize);
%     % Sol = Truncate(Sol);
% end




%---

M(1).Position=Sol;
M(1).Step=zeros(VarSize);
% d0 = 'Set_';
% d = int2str(set_number);
% de = '.csv';
% fname = strcat(d0,d,de)
M(1).Cost=CostFunction(M(1).Position);
% while (1)
%     if exist(fname, 'file')
%         break;
%     end
%     pause(0.2);
% end
BestSol=M(1);

BestCost=zeros(MaxIt,1);

%% CMA-ES Main Loop

for g=1:MaxIt
    
    
    ss111 = set_number;
    % Generate Samples
    pop=repmat(empty_individual,lambda,1);
    for i=1:lambda
        pop(i).Step = mvnrnd(zeros(VarSize),C{g});
        pop(i).Position = M(g).Position+sigma{g}.*pop(i).Step;
        % pop(i).Position = Truncate(pop(i).Position);
        
%         d0 = 'Set_';
%         d = int2str(set_number);
%         de = '.csv';
%         fname = strcat(d0,d,de)
        
        pop(i).Cost=CostFunction(pop(i).Position);
        
%         while (1)
%             if exist(fname, 'file')
%                 break;
%             end
%             pause(0.2);
%         end
        
        % Update Best Solution Ever Found
        if pop(i).Cost<BestSol.Cost
            BestSol=pop(i);
        end
    end
    
    % Sort Population
    Costs=[pop.Cost];
    [Costs, SortOrder]=sort(Costs);
    pop=pop(SortOrder);
    
    % Save Results
    BestCost(g)=BestSol.Cost;
    
    % Display Results
    disp(['Iteration: ' num2str(g) ' Best Cost = ' num2str(BestCost(g)) ' Best Sol = ' num2str(BestSol.Position) ]);
    
       % Exit At Last Iteration
    if g==MaxIt
        break;
    end
    
    % Update Mean
    M(g+1).Step=0;
    for j=1:mu
        M(g+1).Step=M(g+1).Step+w(j)*pop(j).Step;
    end
    M(g+1).Position=M(g).Position+sigma{g}.*M(g+1).Step;
    M(g+1).Cost=CostFunction(M(g+1).Position);
    if M(g+1).Cost<BestSol.Cost
        BestSol=M(g+1);
    end
    
    % Update Step Size
    ps{g+1}=(1-cs)*ps{g}+sqrt(cs*(2-cs)*mu_eff)*M(g+1).Step/chol(C{g})';
    sigma{g+1}=sigma{g}*exp(cs/ds*(norm(ps{g+1})/ENN-1))^0.3;
    
    % Update Covariance Matrix
    if norm(ps{g+1})/sqrt(1-(1-cs)^(2*(g+1)))<hth
        hs=1;
    else
        hs=0;
    end
    delta=(1-hs)*cc*(2-cc);
    pc{g+1}=(1-cc)*pc{g}+hs*sqrt(cc*(2-cc)*mu_eff)*M(g+1).Step;
    C{g+1}=(1-c1-cmu)*C{g}+c1*(pc{g+1}'*pc{g+1}+delta*C{g});
    for j=1:mu
        C{g+1}=C{g+1}+cmu*w(j)*pop(j).Step'*pop(j).Step;
    end
    
    % If Covariance Matrix is not Positive Defenite or Near Singular
    [V, E]=eig(C{g+1});
    if any(diag(E)<0)
        E=max(E,0);
        C{g+1}=V*E/V;
    end
    %BestSol.Position
    if (mod(g,100)==0)
        figure;
        semilogy(BestCost, 'LineWidth', 2);
        xlabel('Iteration');
        ylabel('Best Cost');
        grid on;
        
        prompt = 'If you want the process to stop input pass? \n';
        x1 = input(prompt);
        if (x1 == 123)
            break
        end
    end
        
end

%% Display Results

figure;
% plot(BestCost, 'LineWidth', 2);
semilogy(BestCost, 'LineWidth', 2);
xlabel('Iteration');
ylabel('Best Cost');
grid on;

BestSol.Position