function [P_Kh_lin, P_Kh_nl, P_Khij_lin, P_Khij_nl] = estim_P_K(z_a, z_b, q, q_b , wh, omega, Z, D, X)
G = size(X,1);
X_tmp = [ones(G,1), X];
omega_a = wh(z_a,Z);
omega_b = wh(z_b,Z);
% z_a2 = 3*(z_a1==2) + 2*(z_a1==3) + z_a1*(z_a1==1 | z_a1==4);
% z_b2 = 3*(z_b1==2) + 2*(z_b1==3) + z_b1*(z_b1==1 | z_b1==4);
% omega_a2 = wh(z_a2,Z);
% omega_b2 = wh(z_b2,Z);

P_Kh_lin    = zeros(G,1,2,3);
P_Kh_nl     = zeros(G,1,2,3);
P_Khij_lin  = zeros(G,1,2,3);
P_Khij_nl   = zeros(G,1,2,3);

% Subsample estimation: Linear
% [~,~,Pa1_lin] = estim_IVreg(D_obs(idx_a,:,1), X_tmp(idx_a,:), X_tmp(idx_a,:),X_tmp);
% [~,~,Pb1_lin] = estim_IVreg(D_obs(idx_b,:,1), X_tmp(idx_b,:), X_tmp(idx_b,:),X_tmp);
% [~,~,Pa2_lin] = estim_IVreg(D_obs(idx_a,:,2), X_tmp(idx_a,:), X_tmp(idx_a,:),X_tmp);
% [~,~,Pb2_lin] = estim_IVreg(D_obs(idx_b,:,2), X_tmp(idx_b,:), X_tmp(idx_b,:),X_tmp);
% P_Kh_lin(:,:,1) = Pa1_lin - Pb1_lin;
% P_Kh_lin(:,:,2) = Pa2_lin - Pb2_lin;
% 
% [~,~,Pa1_nl] = estim_BC_opt(D_obs(idx_a,:,1), X_tmp(idx_a,:), q, q_b, 30000, X_tmp);
% [~,~,Pb1_nl] = estim_BC_opt(D_obs(idx_b,:,1), X_tmp(idx_b,:), q, q_b, 30000, X_tmp);
% [~,~,Pa2_nl] = estim_BC_opt(D_obs(idx_a,:,2), X_tmp(idx_a,:), q, q_b, 30000, X_tmp);
% [~,~,Pb2_nl] = estim_BC_opt(D_obs(idx_b,:,2), X_tmp(idx_b,:), q, q_b, 30000, X_tmp);
% P_Kh_nl(:,:,1) = Pa1_nl - Pb1_nl;
% P_Kh_nl(:,:,2) = Pa2_nl - Pb2_nl;

[~,~,P_Kh_nl_C1] = estim_BC_opt(omega.*D(:,:,1), X_tmp, q, q_b, 30000);
[~,~,P_Kh_nl_C2] = estim_BC_opt(omega.*D(:,:,2), X_tmp, q, q_b, 30000);

%[~,~,P_Kh_nl_A1] = estim_BC_opt(omega_b.*D_obs(:,:,1), X_tmp, q, q_b, 30000);
%[~,~,P_Kh_nl_A2] = estim_BC_opt(omega_b.*D_obs(:,:,2), X_tmp, q, q_b, 30000);

[~,~,P_Khij_nl] = estim_BC_opt(omega.*D(:,:,1).*D(:,:,2), X_tmp, q, q_b, 30000);

%P_Kh_nl_N1 = 1-P_Kh_nl_C1;
%P_Kh_nl_N2 = 1-P_Kh_nl_C2;

%P_Kh_nl(:,:,1,1) = P_Kh_nl_A1;
%P_Kh_nl(:,:,2,1) = P_Kh_nl_A2;
P_Kh_nl(:,:,1,2) = P_Kh_nl_C1;
P_Kh_nl(:,:,2,2) = P_Kh_nl_C2;
%P_Kh_nl(:,:,1,3) = P_Kh_nl_N1;
%P_Kh_nl(:,:,2,3) = P_Kh_nl_N2;

[~,~,P_Kh_lin_C1] = estim_IVreg(omega.*D(:,:,1), X_tmp, X_tmp);
[~,~,P_Kh_lin_C2] = estim_IVreg(omega.*D(:,:,2), X_tmp, X_tmp);

%[~,~,P_Kh_lin_A1] = estim_IVreg(omega_b.*D_obs(:,:,1), X_tmp, X_tmp);
%[~,~,P_Kh_lin_A2] = estim_IVreg(omega_b.*D_obs(:,:,2), X_tmp, X_tmp);

[~,~,P_Khij_lin] = estim_IVreg(omega.*D(:,:,1).*D(:,:,2), X_tmp, X_tmp);

%P_Kh_lin_N1 = 1-P_Kh_lin_C1;
%P_Kh_lin_N2 = 1-P_Kh_lin_C2;

%P_Kh_lin(:,:,1,1) = P_Kh_lin_A1;
%P_Kh_lin(:,:,2,1) = P_Kh_lin_A2;
P_Kh_lin(:,:,1,2) = P_Kh_lin_C1;
P_Kh_lin(:,:,2,2) = P_Kh_lin_C2;
%P_Kh_lin(:,:,1,3) = P_Kh_lin_N1;
%P_Kh_lin(:,:,2,3) = P_Kh_lin_N2;
end

