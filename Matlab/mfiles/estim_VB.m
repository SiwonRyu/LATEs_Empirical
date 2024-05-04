function res = estim_VB(Y,D,Z,W,T,Xg,est_fst,z_a,z_b)
%%%%%%%%%%%% Estimation of LATEs with two units %%%%%%%%%%%%%%%%%%%%%%%%%%%
% IV estimation proposed by Vazquez-Bare (2022)
%----------- Input arguments ----------------------------------------------
% - Y, D, Z: Outcome, treatment take-up, assignments (G x 1 x 2)
% - W,  T  : Individual characteristics (G x k x 2) 
% - Wg, Tg : Group characteristics (G x k x 1)
% - z_a,z_b: Part of monotone pair m = (z,z',.) = (z_a, z_b,.)
%            (1/2/3/4) : (1,1)/(1,0)/(0,1)/(0,0)
% - est_fst: (Estimate Z as Probit) Set "true"
%            (Use true coef. for Z) Set (7,2) matrix of true gamma (simulation only)

%----------- Output -------------------------------------------------------
% - result : Estimate table

G = size(Y,1);

%%%%%%%%%%% (A) Estimate P(Z|X) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
q   = @(X,b) normcdf(X*b);
dq  = @(X,b) normpdf(X*b).*X;
[gamma_est, ~, q_z_ind, ~] = estim_Z(q,dq,Z,W,T,Xg);

if isnumeric(est_fst) == 0 % Use true gamma (simulation only)
    %display('use est g')
else
    %display('use true g')
    gamma_est = est_fst;
end

% Indicators: 1(Z=z)
idx = @(z, Z) ...
     (z==1).*(Z(:,:,1)==1 & Z(:,:,2)==1) ...
    +(z==2).*(Z(:,:,1)==1 & Z(:,:,2)==0) ...
    +(z==3).*(Z(:,:,1)==0 & Z(:,:,2)==1) ...
    +(z==4).*(Z(:,:,1)==0 & Z(:,:,2)==0);

% Pr(Z=z|W,T) at the estimated gamma
q_z =@(z,gamma) ...
     (z==1).*   q_z_ind(1,gamma(:,1)).*    q_z_ind(2,gamma(:,2))  ...
    +(z==2).*   q_z_ind(1,gamma(:,1)).* (1-q_z_ind(2,gamma(:,2))) ...
    +(z==3).*(1-q_z_ind(1,gamma(:,1))).*   q_z_ind(2,gamma(:,2))  ...
    +(z==4).*(1-q_z_ind(1,gamma(:,1))).*(1-q_z_ind(2,gamma(:,2)));

% Weight omega(z,Z,X)
w = @(z, Z, gamma) idx(z,Z)./q_z(z, gamma);
w = @(z, Z) w(z, Z, gamma_est);

% Omega, and its derivative (w.r.t. gamma, (G x 14))
omega   = w(z_a,Z)  - w(z_b,Z);


%%%%%%%%%%% (B) Estimate IV regression of Y_i on D with IV Z %%%%%%%%%%%%%%
Y1 = Y(:,:,1);
Y2 = Y(:,:,2);
D1 = D(:,:,1);
D2 = D(:,:,2);

Yg = permute(cat(3,omega.*Y1,omega.*Y2),[3,2,1]);
if  z_a == 2    & z_b == 4 % (1,0) - (0,0) : P_K of Unit 2 is zero
    Xg = cat(2,cat(1,permute(omega.*D1,[3,2,1]),zeros(1,1,G)),cat(1,zeros(1,1,G),permute(omega.*D1,[3,2,1])));
elseif z_a == 3 & z_b == 4 % (0,1) - (0,0) : P_K of Unit 1 is zero
    Xg = cat(2,cat(1,permute(omega.*D2,[3,2,1]),zeros(1,1,G)),cat(1,zeros(1,1,G),permute(omega.*D2,[3,2,1])));
end

gmm     = @(Y,X,W) (mean(X,3)'*W*mean(X,3))\(mean(X,3)'*W*mean(Y,3));
gmm_1st = gmm(Yg,Xg,eye(2));

mom     = @(Y,X,b) Y - sum(X.*repmat(diag(b),[1,1,size(Y,3)]),2);
mom_1st = mom(Yg,Xg,gmm_1st);
S       = mean(mom_1st.*permute(mom_1st,[2,1,3]),3);

Var     = inv(mean(Xg,3)'*inv(S)*mean(Xg,3))/G;
SE      = diag(sqrt(Var));
t       = gmm_1st./SE;
p       = 2*(1-normcdf(abs(t)));

res     = [gmm_1st, SE, t, p];
end