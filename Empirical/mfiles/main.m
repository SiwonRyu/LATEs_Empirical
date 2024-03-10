addpath("C:\rsw\Replication Datasets\Codes_for_3YP\Empirical\mfiles")

run import_xlsx.m

%% 1st-stage
clc
format compact

% Estimate P_Z
q   = @(X,b) normcdf(X*b);
q_b = @(X,b) normpdf(X*b).*X;
[b_z_est, IF_gamma, q_iz, q_biz] = est_Z_new(q,q_b,Z,W,T,Xg);

% Indicators: 1(Z=z)
idx = @(z, Z) ...
     (z==1).*(Z(:,:,1)==1 & Z(:,:,2)==1) ...
    +(z==2).*(Z(:,:,1)==1 & Z(:,:,2)==0) ...
    +(z==3).*(Z(:,:,1)==0 & Z(:,:,2)==1) ...
    +(z==4).*(Z(:,:,1)==0 & Z(:,:,2)==0);

% q(z,W,T;gamma) = Pr(Z=z|W,T) at the true gamma
q_zt =@(z,b_z) ...
     (z==1).*q_iz(1,b_z(:,:,1)).*q_iz(2,b_z(:,:,2)) ...
    +(z==2).*q_iz(1,b_z(:,:,1)).*(1-q_iz(2,b_z(:,:,2))) ...
    +(z==3).*(1-q_iz(1,b_z(:,:,1))).*q_iz(2,b_z(:,:,2)) ...
    +(z==4).*(1-q_iz(1,b_z(:,:,1))).*(1-q_iz(2,b_z(:,:,2)));

% Pr(Z=z|W,T) at the estimated gamma
q_zh =@(z) ...
     (z==1).*q_iz(1,b_z_est(:,1)).*q_iz(2,b_z_est(:,2)) ...
    +(z==2).*q_iz(1,b_z_est(:,1)).*(1-q_iz(2,b_z_est(:,2))) ...
    +(z==3).*(1-q_iz(1,b_z_est(:,1))).*q_iz(2,b_z_est(:,2)) ...
    +(z==4).*(1-q_iz(1,b_z_est(:,1))).*(1-q_iz(2,b_z_est(:,2)));

% Derivative of q w.r.t. gamma
q_bzh =@(z) ...
     (z==1).*[ q_biz(1,b_z_est(:,1)).*   q_iz(2,b_z_est(:,2)) ,     q_iz(1,b_z_est(:,1)) .* q_biz(2,b_z_est(:,2))] ...
    +(z==2).*[ q_biz(1,b_z_est(:,1)).*(1-q_iz(2,b_z_est(:,2))),     q_iz(1,b_z_est(:,1)) .*-q_biz(2,b_z_est(:,2))] ...
    +(z==3).*[-q_biz(1,b_z_est(:,1)).*   q_iz(2,b_z_est(:,2)) ,  (1-q_iz(1,b_z_est(:,1))).* q_biz(2,b_z_est(:,2))] ...
    +(z==4).*[-q_biz(1,b_z_est(:,1)).*(1-q_iz(2,b_z_est(:,2))),  (1-q_iz(1,b_z_est(:,1))).*-q_biz(2,b_z_est(:,2))];

% Weight omega(z,Z,X)
wt = @(z, Z) idx(z,Z)./q_zt(z);
wh = @(z, Z) idx(z,Z)./q_zh(z);

% Derivative of weight
Pwh = @(z,Z) (-idx(z,Z)./(q_zh(z).^2)).*q_bzh(z);


% Set Monotone Pair (z, z') = (za_1, zb_1)
% 1: (0,0) / 2: (1,0) / 3: (0,1) / 4: (0,0)
z_a1 = 2;
z_b1 = 4;

% Omega, and its derivative (w.r.t. gamma, (G x 14))
omegah  = wh(z_a1,Z)  - wh(z_b1,Z);
Pomegah = Pwh(z_a1,Z) - Pwh(z_b1,Z);

% Estimate P_K for instrument
%[P_Kt, P_Ktij] = est_P_K_infeasible(z_a1, z_b1, z_a2, z_b2, T, D_pot, q, q_b);
[P_Kh_lin_all, P_Kh_nl_all, P_Khij_lin, P_Khij_nl] = est_P_K_new(z_a1,z_b1,q,q_b,wh, omegah,Z, D_obs ,[T(:,:,1), T(:,:,2), Tg]);

display('Mean compliance distribution (A/C/N)x(Linear/Nonlinear)')
squeeze(mean(P_Kh_lin_all))
squeeze(mean(P_Kh_nl_all))

display('Mean joint compliance distribution P_{ij} (Linear/Nonlinear)')
[squeeze(mean(P_Khij_lin))', squeeze(mean(P_Khij_nl))']

P_Kh_lin = P_Kh_lin_all(:,:,:,2);
P_Kh_nl  = P_Kh_nl_all(:,:,:,2);


%% for cross monotonicity
% 1st Stage IV
IV_tmp = [T(:,:,1), T(:,:,2), Tg];


[b1r,e1,Yhat1r, IF_1st_1r, SE_1st_1r, T_1st_1r, P_1st_1r, ~, X_hat1r] ...
    = IVe(omegah.*Y_obs(:,:,1), omegah.*[D_obs(:,:,1),D_obs(:,:,2)], IV_tmp);
[b2r,e2,Yhat2r, IF_1st_2r, SE_1st_2r, T_1st_2r, P_1st_2r, ~, X_hat2r] ...
    = IVe(omegah.*Y_obs(:,:,2), omegah.*[D_obs(:,:,2),D_obs(:,:,1)], IV_tmp);

[b1r, SE_1st_1r, T_1st_1r, P_1st_1r];
[b2r, SE_1st_2r, T_1st_2r, P_1st_2r];


% Homogeneous Error Variance
A1r = X_hat1r'*X_hat1r/G; % separate variance
A2r = X_hat2r'*X_hat2r/G;
s1 = A1r\(X_hat1r.*e1)';
s2 = A2r\(X_hat2r.*e2)';
S_homo_j = [e1,e2]'*[e1,e2]/G; % joint


% Compute summands: (a x b x G) matrices
nIV         = 2; % # of methods for compute IV (linear, nonlinear)
nPD         = 2; % # of independent variables in ITT equation (Pi,Pj)
nUnit       = 2; % # of units (female, male)
nMom        = 1; % # of moments being stacked (separated)
mat_Y       = permute(Y_obs,[3,1,2]);
mat_P       = zeros(nUnit       , nUnit*nPD ,G, nIV);
mat_D       = zeros(nUnit       , nUnit*nPD ,G);
mat_IV      = zeros(nUnit*nPD   , nUnit     ,G ,nIV);
mat_Denh    = zeros(nUnit*nPD   , nUnit*nPD ,G ,nIV);
mat_Numh    = zeros(nUnit*nPD   , 1         ,G ,nIV);

mat_Si          = repmat(inv(S_homo_j),[1,1,G]);

mat_P(:,:,:,1)  = V_stack(P_Kh_nl);
mat_P(:,:,:,2)  = V_stack(P_Kh_lin);
mat_D           = V_stack(D_obs);

beta_2ndt       = zeros(nUnit*nPD, 1, nIV);
beta_2ndh       = zeros(nUnit*nPD, 1, nIV);
IF_betat        = zeros(G, nUnit*nPD, nIV);
IF_betah        = zeros(G, nUnit*nPD, nIV);
mat_B_pret      = zeros(nUnit*nPD, 1, G, nIV);
mat_B_preh      = zeros(nUnit*nPD, 1, G, nIV);

for s=1:nIV
    mat_IV(:,:,:,s) = AtimesB_C(mat_P(:,:,:,s), mat_Si(:,:,:));
    mat_Denh(:,:,:,s) = permute(omegah,[2,3,1]).*AtimesB_C(permute(mat_IV(:,:,:,s),[2,1,3,4]), mat_D);
    mat_Numh(:,:,:,s) = permute(omegah,[2,3,1]).*AtimesB_C(permute(mat_IV(:,:,:,s),[2,1,3,4]), permute(mat_Y,[1,3,2]));

    % 2nd stage IV estimator (Opitmal IV)    
    beta_2ndh(:,:,s) = mean(mat_Denh(:,:,:,s),3)\mean(mat_Numh(:,:,:,s),3);
    
    % Compute Empirical Influence function
    mat_B_preh(:,:,:,s) = AtimesB_C( ...
        permute(mat_IV(:,:,:,s),[2,1,3]), ... % IV
        (permute(mat_Y,[1,3,2])-sum(mat_D.*beta_2ndh(:,:,s)',2)) ); % epsilon = Y - Db
    IF_betah(:,:,s) = omegah.*permute(mat_B_preh(:,:,:,s),[3,2,1]);
end


% Compute Standard Error
% (a) From Influence function,
IF_gamma_rs = [IF_gamma(:,:,1), IF_gamma(:,:,2)];

mat_Ao  = @(IF_beta)    IF_beta'*IF_beta/G; % (4x4) A when using optimal IV
mat_A   = @(mat_Den)    mean(mat_Den,3);    % (4x4)
mat_B   = @(mat_B_pre)  mean(mat_B_pre.*permute(Pomegah,[3,2,1]),3)'; % (4x1xG) x (1x14xG) = (4 x 14 x G) => (4x14)
mat_IFt = @(IF_beta, A)             IF_beta;
mat_IFh = @(IF_beta, mat_B_pre, A)  IF_beta + IF_gamma_rs*mat_B(mat_B_pre);

Avarh   = zeros(nUnit*nPD, nUnit*nPD, nIV);
Seh     = zeros(nUnit*nPD, 1,         nIV);

for s=1:nIV
    Aoh     = mat_Ao(IF_betah(:,:,s));
    % Ah      = mat_A(mat_Denh(:,:,:,s));
    % At      = mat_A(mat_Dent(:,:,:,s));
    vtmph   = mat_IFh(IF_betah(:,:,s), mat_B_preh(:,:,:,s));
    Avarh(:,:,s) = inv(Aoh)*(vtmph'*vtmph/G)*inv(Aoh);
    Seh(:,:,s) = sqrt(diag(Avarh(:,:,s)/G));
end

res = zeros(4,5,6);
t_crit = abs(icdf('T',0.025,G-nUnit*nPD));

UB_t  = zeros(nUnit*nPD,1,nIV);LB_t = zeros(nUnit*nPD,1,nIV);
cov_t = zeros(nUnit*nPD,1,nIV);
UB_h  = zeros(nUnit*nPD,1,nIV);LB_h = zeros(nUnit*nPD,1,nIV);
cov_h = zeros(nUnit*nPD,1,nIV);
T_t   = zeros(nUnit*nPD,1,nIV);
Pv_t  = zeros(nUnit*nPD,1,nIV);

for s = 1:nIV
UB_h(:,:,s) = beta_2ndh(:,:,s) + t_crit*Seh(:,:,s);
LB_h(:,:,s) = beta_2ndh(:,:,s) - t_crit*Seh(:,:,s);
T_t(:,:,s)  = beta_2ndh(:,:,s)./Seh(:,:,s);
Pv_t(:,:,s) = 2*(1-cdf('T',abs(T_t(:,:,s)), G-nUnit*nPD));
end

res_eo_n_s = [repmat(G,nUnit*nPD,1), beta_2ndh(:,:,1), Seh(:,:,1), T_t(:,:,1), Pv_t(:,:,1), LB_h(:,:,1), UB_h(:,:,1)];
res_eo_l_s = [repmat(G,nUnit*nPD,1), beta_2ndh(:,:,2), Seh(:,:,2), T_t(:,:,2), Pv_t(:,:,2), LB_h(:,:,2), UB_h(:,:,2)];

IF_gamma_tmp = IF_gamma_rs*mean(permute(cat(1,s1,s2),[1,3,2]).*permute(Pomegah,[3,2,1]),3)';
IF_1st_iv = cat(2,IF_1st_1r, IF_1st_2r);
IF_1st    = IF_1st_iv + IF_gamma_tmp;
beta_1st  = [b1r; b2r];
SE_1st    = sqrt(diag(IF_1st'*IF_1st/G)/G);
T_1st     = beta_1st./SE_1st;
Pv_1st    = 2*(1-cdf('T',abs(T_1st), G-4));
LB_1st    = beta_1st - t_crit*SE_1st;
UB_1st    = beta_1st + t_crit*SE_1st;
res_1st   = [repmat(G,4,1), beta_1st, SE_1st, T_1st, Pv_1st, LB_1st, UB_1st];

res       = cat(3, res_eo_n_s, res_eo_l_s, res_1st )
res_sel   = res_eo_l_s(:,2:5);
%res_sel(6,:) = [];
%res_sel(3,:) = []