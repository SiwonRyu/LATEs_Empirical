function [b, IF, P, P_b] = est_Z_new(q,q_b,Z,W,T,X_g)
    G   = size(Z,1);
    Y   = @(i) Z(:,:,i);
    if nargin == 6
        X = @(i) [ones(G,1), W(:,:,i), W(:,:,3-i), T(:,:,i), T(:,:,3-i), X_g(:,:)];
    else
        X = @(i) [ones(G,1), W(:,:,i), W(:,:,3-i), T(:,:,i), T(:,:,3-i)];
    end
    k   = size(X(1),2);
    b   = zeros(k,2);
    IF  = zeros(G,k,2);

    % Pr(Z=(z1,z2)|X)
    P   = @(i,b_z) q(X(i), b_z);
    P_b = @(i,b_z) q_b(X(i), b_z);
    for i = 1:2
        [b(:,i), ~, ~, IF(:,:,i), ~,~,~,~] = BCM_Opt(Y(i), X(i), q, q_b, 30000);
    end
end


