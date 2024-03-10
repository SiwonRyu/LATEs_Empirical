function [b, r, Yhat, IF, SE, t, p, Avar] = BCM_Opt(Y,X,q,q_b, maxiter, X_pred, Y_pred)
    % Optimal IV estimation of Binary Dependent Variable
    options = optimset('MaxFunEvals',maxiter, 'Display', 'off');
    [n,k]   = size(X);

    b0      = (X'*X)\(X'*Y);
    %b0 = zeros(size(X,2),1);
    
    resid   = @(b_z) Y-q(X,b_z);
    sig     = @(b_z) q(X,b_z) .* (1-q(X,b_z));
    score   = @(b_z) q_b(X,b_z).*[resid(b_z)./sig(b_z)];
    hess    = @(b_z) (q_b(X,b_z)./sig(b_z))'*q_b(X,b_z)/n;
    obj     = @(b_z) mean(score(b_z),1)';
    b       = fsolve(obj, b0, options);

    if nargin == 7 % Out ot sample prediction
        Yhat  = q(X_pred,b);
        r     = Y_pred-Y_hat;
    elseif nargin == 6
        Yhat  = q(X_pred,b);
        r     = resid(b);
    else
        Yhat  = q(X,b);
        r     = Y-Yhat;
    end

    IF = (hess(b)\score(b)')';
    [SE,t,p,Avar] = Inf_t(b, r, IF);
end