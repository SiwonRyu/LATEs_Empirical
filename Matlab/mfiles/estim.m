function [result,omega,P_K_all,P_K_ij] = estim(Y,D,Z,W,T,Tg,Xg,z_a,z_b,est_fst,est_P_K,cs,dis)
%%%%%%%%%%%% Estimation of LATEs with two units %%%%%%%%%%%%%%%%%%%%%%%%%%%
% Last updated on May, 04, 2024, by Siwon Ryu
%----------- Input arguments ----------------------------------------------
% - Y, D, Z: Outcome, treatment take-up, assignments (G x 1 x 2)
% - W,  T  : Individual characteristics (G x k x 2) 
% - Wg, Tg : Group characteristics (G x k x 1)
% - z_a,z_b: Part of monotone pair m = (z,z',.) = (z_a, z_b,.)
%            (1/2/3/4) : (1,1)/(1,0)/(0,1)/(0,0)
% - est_fst: (Estimate Z as Probit) Set "true"
%            (Use true coef. for Z) Set (7,2) matrix of true gamma (simulation only)
% - est_P_K: Method for estimating distribution of compliance types
%            (Linear Prob. Model)   Set "lin"
%            (Probit Model)         Set "nl"
% - cs:      Special case indicator
%            (Use general ID)       Set 0 
%            (Use speical case 1)   Set 1
%            (Use speical case 2)   Set 2
% - dis:     Display indicator. "on"/"off"

%----------- Output -------------------------------------------------------
% - result : Estimate table
% - omgea  : Weight to compute ITT
% - P_K_all: Estimated distribution of K_i
% - P_K_ij : Estimated distribution of K_ij

G = size(Y,1);

%%%%%%%%%%% (A) Estimate P(Z|X) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
q   = @(X,b) normcdf(X*b);
dq  = @(X,b) normpdf(X*b).*X;
[gamma_est, IF_gamma, q_z_ind, dq_z_ind] = estim_Z(q,dq,Z,W,T,Xg);

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

% Derivative of q w.r.t. gamma
dq_z =@(z,gamma) ...
     (z==1).*[ dq_z_ind(1,gamma(:,1)).*   q_z_ind(2,gamma(:,2)) ,     q_z_ind(1,gamma(:,1)) .* dq_z_ind(2,gamma(:,2))] ...
    +(z==2).*[ dq_z_ind(1,gamma(:,1)).*(1-q_z_ind(2,gamma(:,2))),     q_z_ind(1,gamma(:,1)) .*-dq_z_ind(2,gamma(:,2))] ...
    +(z==3).*[-dq_z_ind(1,gamma(:,1)).*   q_z_ind(2,gamma(:,2)) ,  (1-q_z_ind(1,gamma(:,1))).* dq_z_ind(2,gamma(:,2))] ...
    +(z==4).*[-dq_z_ind(1,gamma(:,1)).*(1-q_z_ind(2,gamma(:,2))),  (1-q_z_ind(1,gamma(:,1))).*-dq_z_ind(2,gamma(:,2))];

% Weight omega(z,Z,X)
w = @(z, Z, gamma) idx(z,Z)./q_z(z, gamma);
w = @(z, Z) w(z, Z, gamma_est);

% Derivative of weight
dw = @(z,Z, gamma) (-idx(z,Z)./(q_z(z, gamma).^2)).*dq_z(z, gamma);

% Omega, and its derivative (w.r.t. gamma, (G x 14))
omega   = w(z_a,Z)  - w(z_b,Z);
domega  = dw(z_a,Z, gamma_est) - dw(z_b,Z, gamma_est);



%%%%%%%%%%% (B) Estimate P(K|T) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[P_Kh_lin_all, P_Kh_nl_all, P_Khij_lin, P_Khij_nl] = estim_P_K(z_a,z_b,q,dq,w,omega,Z, D ,[T(:,:,1), T(:,:,2), Tg]);
if est_P_K == "lin"
    P_K_all = P_Kh_lin_all;
    P_K_ij = P_Khij_lin;
elseif est_P_K == "nl"
    P_K_all = P_Kh_nl_all;
    P_K_ij = P_Khij_nl;
end
if dis == 'on'
    display('Mean compliance distribution (A/C/N)x(Linear/Nonlinear)')
    squeeze(mean(P_K_all))

    display('Mean joint compliance distribution P_{ij} (Linear/Nonlinear)')
    [squeeze(mean(P_K_ij))']
end



%%%%%%%%%%% (C) Check Overlapping Assumptions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
check_OVL1      = sum((idx(z_a,Z)-idx(z_b,Z)).*D(:,:,1));
check_OVL2      = sum((idx(z_a,Z)-idx(z_b,Z)).*D(:,:,2));
check_OVLjoint  = sum((idx(z_a,Z)-idx(z_b,Z)).*prod(D,3));

if check_OVL1 == 0 & check_OVL2 == 0
    sp = 9; % Error
elseif check_OVL1 == 0 | check_OVL2 == 0
    % OVL violated -> go to special case 2
    sp = 2;
elseif check_OVL1 == check_OVLjoint | check_OVL2 == check_OVLjoint | check_OVLjoint == 0
    % If check_OVL1 or check_OLV2 is zero, then check_OVL should be 0
    % OVL violated -> go to speical case 1 and omit the third term
    sp = 1;
else
    sp = 0;
end

% Display alert
if cs < sp
    if dis == 'on'
    disp(['Case set by ', num2str(cs), ...
       ' but data does not satisfy the requirements'])
    disp(['Check OVL (1/2/joint): ', num2str(check_OVL1), ...
       '/', num2str(check_OVL2), ...
       '/', num2str(check_OVLjoint)])
    disp(['Estimate speical case ', num2str(sp)])
    end   
else 
    if dis == 'on'
    disp(['Case set by ', num2str(cs)])
    disp(['Check OVL (1/2/joint): ', num2str(check_OVL1), ...
       '/', num2str(check_OVL2), ...
       '/', num2str(check_OVLjoint)])
    end
   sp = cs;
end



%%%%%%%%%%% (D) 1st Stage IV %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if sp == 2
    % It is possible for check_OVL2 to be positive for the DGP of
    % special case 2. For example, D(0,1) = D(0,0) with probability 1,
    % but both can have value of {0,1}. Their realization can be
    % different. However, the number of D(0,1) != D(0,0) in sample must
    % tend to zero. The following sel_unit_1 is indicator of unit 1
    % being complier, but unit 2's compliance pattern doesn't change
    sel_unit_1  = (check_OVL1 > check_OVL2) + 2*(check_OVL1 < check_OVL2);
    IV_tmp      = [T(:,:,1), T(:,:,2), Tg];
    D_sel       = D(:,:,sel_unit_1);
    P_K         = P_K_all(:,:,sel_unit_1,2);
    X_tmp1      = omega.*[D_sel];
    X_tmp2      = X_tmp1;
elseif sp == 1
    IV_tmp      = [T(:,:,1), T(:,:,2), Tg];
    P_K         = P_K_all(:,:,:,2);
    X_tmp1      = omega.*[D(:,:,1),D(:,:,2)];
    X_tmp2      = omega.*[D(:,:,2),D(:,:,1)];
elseif sp == 0
    IV_tmp      = [T(:,:,1), T(:,:,2), T(:,:,1).*T(:,:,2), Tg];
    P_K         = P_K_all(:,:,:,2);
    X_tmp1      = omega.*[D(:,:,1),D(:,:,2),D(:,:,1).*D(:,:,2)];
    X_tmp2      = omega.*[D(:,:,2),D(:,:,1),D(:,:,1).*D(:,:,2)];
end

[beta_1st_1,resid_1st_1,~,~,SE_1st_1, T_1st_1, P_1st_1,~,~] = estim_IVreg(omega.*Y(:,:,1),X_tmp1,IV_tmp);
[beta_1st_2,resid_1st_2,~,~,SE_1st_2, T_1st_2, P_1st_2,~,~] = estim_IVreg(omega.*Y(:,:,2),X_tmp2,IV_tmp);
%[beta_1st_1, SE_1st_1, T_1st_1, P_1st_1];
%[beta_1st_2, SE_1st_2, T_1st_2, P_1st_2];



%%%%%%%%%%% (E) Compute optimal IV %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
S_homo = [resid_1st_1,resid_1st_2]'*[resid_1st_1,resid_1st_2]/G; % Homogeneous Error Variance

% Compute summands: (a x b x G) matrices
mat_Y       = permute(Y,[3,1,2]);
mat_Si      = repmat(inv(S_homo),[1,1,G]);

if sp == 0
    mat_P       = V_stack_ij(P_K, P_K_ij);
    mat_D       = V_stack_ij(D, D(:,:,1).*D(:,:,2));
elseif sp == 1
    mat_P       = V_stack(P_K);
    mat_D       = V_stack(D);  
elseif sp == 2
    mat_P       = V_stack(P_K);
    mat_D       = V_stack(D_sel);  
end



%%%%%%%%%%% (F) 2nd stage IV estimator (Opitmal IV) %%%%%%%%%%%%%%%%%%%%%%%
IV       = AtimesB_C(mat_P, mat_Si);
RwD      = permute(omega,[2,3,1]).*AtimesB_C(permute(IV,[2,1,3]), mat_D);
RwY      = permute(omega,[2,3,1]).*AtimesB_C(permute(IV,[2,1,3]), permute(mat_Y,[1,3,2]));
beta_2nd = mean(RwD,3)\mean(RwY,3);



%%%%%%%%%%% (G) Compute Empirical Influence function %%%%%%%%%%%%%%%%%%%%%%
Re      = AtimesB_C( permute(IV,[2,1,3]), ... % IV = R
        (permute(mat_Y,[1,3,2])-sum(mat_D.*beta_2nd',2)) ); % e = Y - Db
Rwe    = omega.*permute(Re,[3,1,2]);



%%%%%%%%%%% (H) Compute Standard Error %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% reshape influence function of estimated gamma
IF_gamma_rs = [IF_gamma(:,:,1), IF_gamma(:,:,2)]; 

% Construct matrix B = Sum (R x e x dw)
mat_B   = @(Re) mean(Re.*permute(domega,[3,2,1]),3)'; % (4x1xG) x (1x14xG) = (4 x 14 x G) => (4x14)

% Construct matrix A = sum (P x inv(S) x P') = sum (IF x IF')
PSiP    = AtimesB_C(permute(  AtimesB_C(mat_P, mat_Si)  ,[2,1,3]), mat_P);
mat_A   = mean(PSiP,3);
%mat_A    = IF_beta'*IF_beta/G;

if isnumeric(est_fst) == 0
    IF_beta = Rwe + IF_gamma_rs*mat_B(Re); % Correction of 1st stage estim
else
    IF_beta = Rwe;
end
Avar    = inv(mat_A)*(IF_beta'*IF_beta/G)*inv(mat_A);
Se      = sqrt(diag(Avar/G));



%%%%%%%%%%% (I) Compute statistics and return results %%%%%%%%%%%%%%%%%%%%%
crit    = abs(icdf('Normal',0.975,0,1));
UB      = beta_2nd + crit*Se;
LB      = beta_2nd - crit*Se;
z_score = beta_2nd./Se;
p_val   = 2*(1-normcdf(abs(beta_2nd./Se)));

result  = [beta_2nd, Se, z_score, p_val];
end





%%%%%%%%%%%%%%%%%%%%% Auxiliary functions defined %%%%%%%%%%%%%%%%%%%%%%%%%
function AB = AtimesB_C(A,B)
% A, B: NxKxG
% A(:,:,g)'*B(:,:,g) = (KxN) x (NxK)
AB_tmp = permute(A,[2,1,4,3]).*permute(B,[4,1,2,3]);
AB = permute(sum(AB_tmp,2),[1,3,4,2]);    
end

function V = V_stack(M)
    % Input: M is Gx1xN
    G = size(M,1);
    N = size(M,3);
    if N == 1
    M1 = M(:,:,1);
    
    z_tmp = zeros(1,1,G);
    V1 = permute(M1,[2,3,1]);
    V   = cat(1, ...
        cat(2, V1, z_tmp), ...
        cat(2, z_tmp, V1));
    
    else
    M1 = M(:,:,1);
    M2 = M(:,:,2);
    
    z_tmp = zeros(1,1,G);
    V1 = permute(M1,[2,3,1]);
    V2 = permute(M2,[2,3,1]);
    
    V11 = cat(2,V1,V2);
    V12 = cat(2,z_tmp,z_tmp);
    V22 = cat(2,V2,V1);
    
    V   = cat(1, ...
        cat(2, V11, V12), ...
        cat(2, V12, V22));
    end
end

function V = V_stack_ij(M,M12)
    % Input: M is Gx1xN
    M1 = M(:,:,1);
    M2 = M(:,:,2);
    
    G = size(M1,1);
    
    z_tmp = zeros(1,1,G);
    V1 = permute(M1,[2,3,1]);
    V2 = permute(M2,[2,3,1]);
    M12 = permute(M12,[2,3,1]);
    
    V11 = cat(2,V1,V2,M12);
    V12 = cat(2,z_tmp,z_tmp,z_tmp);
    V22 = cat(2,V2,V1,M12);
    
    V   = cat(1, ...
        cat(2, V11, V12), ...
        cat(2, V12, V22));
end