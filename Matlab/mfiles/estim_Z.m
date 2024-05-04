function [b, IF, P, dP] = estim_Z(q,dq,Z,W,T,X_g)
    G   = size(Z,1);
    Y   = @(i) Z(:,:,i);
    if nargin == 6 % If group characteristic exists
        X = @(i) [ones(G,1), W(:,:,i), W(:,:,3-i), T(:,:,i), T(:,:,3-i), X_g(:,:)];
    else
        X = @(i) [ones(G,1), W(:,:,i), W(:,:,3-i), T(:,:,i), T(:,:,3-i)];
    end
    k   = size(X(1),2);
    b   = zeros(k,2);
    IF  = zeros(G,k,2);

    % Pr(Z=(z1,z2)|X)
    P   = @(i,gamma)  q(X(i), gamma);
    dP  = @(i,gamma) dq(X(i), gamma); % derivative of P
    for i = 1:2
        [b(:,i), ~, ~, IF(:,:,i), ~,~,~,~] = estim_BC_opt(Y(i),X(i),q,dq,30000);
    end
end