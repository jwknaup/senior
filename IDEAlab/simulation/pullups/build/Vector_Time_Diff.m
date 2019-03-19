function [ Error ] = Vector_Time_Diff(X1,X2)

T1 = X1(:,1);
T2 = X2(:,1);
D1 = X1(:,2);
D2 = X2(:,2);

% Let's consider X1 as reference

D2_modified = zeros(size(D1));


for i=1:max(size(T1))
    Tref = T1(i);
    T_diff_Vec = abs(T2 - Tref);
    [Tv Tn] = min(T_diff_Vec);
    D2_modified(i) = D2(Tn);
    
end

Error = norm(D1-D2_modified);
end

