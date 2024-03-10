function [P_Kh_lin, P_Kh_nl, P_Khij_lin, P_Khij_nl] = est_P_K_new(z_a1, z_b1, q, q_b , wh, omega, Z, D_obs, X)
G = size(X,1);
X_tmp = [ones(G,1), X];
omega_a = wh(z_a1,Z);
omega_b = wh(z_b1,Z);

P_Kh_lin    = zeros(G,1,2,3);
P_Kh_nl     = zeros(G,1,2,3);
P_Khij_lin  = zeros(G,1,2,3);
P_Khij_nl   = zeros(G,1,2,3);

% Subsample estimation: Linear
% [~,~,Pa1_lin] = IVe(D_obs(idx_a,:,1), X_tmp(idx_a,:), X_tmp(idx_a,:),X_tmp);
% [~,~,Pb1_lin] = IVe(D_obs(idx_b,:,1), X_tmp(idx_b,:), X_tmp(idx_b,:),X_tmp);
% [~,~,Pa2_lin] = IVe(D_obs(idx_a,:,2), X_tmp(idx_a,:), X_tmp(idx_a,:),X_tmp);
% [~,~,Pb2_lin] = IVe(D_obs(idx_b,:,2), X_tmp(idx_b,:), X_tmp(idx_b,:),X_tmp);
% P_Kh_lin(:,:,1) = Pa1_lin - Pb1_lin;
% P_Kh_lin(:,:,2) = Pa2_lin - Pb2_lin;
% 
% [~,~,Pa1_nl] = BCM_Opt(D_obs(idx_a,:,1), X_tmp(idx_a,:), q, q_b, 30000, X_tmp);
% [~,~,Pb1_nl] = BCM_Opt(D_obs(idx_b,:,1), X_tmp(idx_b,:), q, q_b, 30000, X_tmp);
% [~,~,Pa2_nl] = BCM_Opt(D_obs(idx_a,:,2), X_tmp(idx_a,:), q, q_b, 30000, X_tmp);
% [~,~,Pb2_nl] = BCM_Opt(D_obs(idx_b,:,2), X_tmp(idx_b,:), q, q_b, 30000, X_tmp);
% P_Kh_nl(:,:,1) = Pa1_nl - Pb1_nl;
% P_Kh_nl(:,:,2) = Pa2_nl - Pb2_nl;

[~,~,P_Kh_nl_C1] = BCM_Opt(omega.*D_obs(:,:,1), X_tmp, q, q_b, 30000);
[~,~,P_Kh_nl_C2] = BCM_Opt(omega.*D_obs(:,:,2), X_tmp, q, q_b, 30000);

[~,~,P_Kh_nl_A1] = BCM_Opt(omega_b.*D_obs(:,:,1), X_tmp, q, q_b, 30000);
[~,~,P_Kh_nl_A2] = BCM_Opt(omega_b.*D_obs(:,:,2), X_tmp, q, q_b, 30000);

[~,~,P_Khij_nl] = BCM_Opt(omega.*D_obs(:,:,1).*D_obs(:,:,2), X_tmp, q, q_b, 30000);

P_Kh_nl_N1 = 1-P_Kh_nl_C1;
P_Kh_nl_N2 = 1-P_Kh_nl_C2;

P_Kh_nl(:,:,1,1) = P_Kh_nl_A1;
P_Kh_nl(:,:,2,1) = P_Kh_nl_A2;
P_Kh_nl(:,:,1,2) = P_Kh_nl_C1;
P_Kh_nl(:,:,2,2) = P_Kh_nl_C2;
P_Kh_nl(:,:,1,3) = P_Kh_nl_N1;
P_Kh_nl(:,:,2,3) = P_Kh_nl_N2;

[~,~,P_Kh_lin_C1] = IVe(omega.*D_obs(:,:,1), X_tmp, X_tmp);
[~,~,P_Kh_lin_C2] = IVe(omega.*D_obs(:,:,2), X_tmp, X_tmp);

[~,~,P_Kh_lin_A1] = IVe(omega_b.*D_obs(:,:,1), X_tmp, X_tmp);
[~,~,P_Kh_lin_A2] = IVe(omega_b.*D_obs(:,:,2), X_tmp, X_tmp);

[~,~,P_Khij_lin] = IVe(omega.*D_obs(:,:,1).*D_obs(:,:,2), X_tmp, X_tmp);

P_Kh_lin_N1 = 1-P_Kh_lin_C1;
P_Kh_lin_N2 = 1-P_Kh_lin_C2;

P_Kh_lin(:,:,1,1) = P_Kh_lin_A1;
P_Kh_lin(:,:,2,1) = P_Kh_lin_A2;
P_Kh_lin(:,:,1,2) = P_Kh_lin_C1;
P_Kh_lin(:,:,2,2) = P_Kh_lin_C2;
P_Kh_lin(:,:,1,3) = P_Kh_lin_N1;
P_Kh_lin(:,:,2,3) = P_Kh_lin_N2;
end

