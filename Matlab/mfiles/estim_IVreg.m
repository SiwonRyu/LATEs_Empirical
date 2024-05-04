function [b, r, Yhat, IF, SE, t, p, Avar, X_hat] = estim_IVreg(Y,X,IV,X_pred,Y_pred)
    [n,k] = size(X);
    b = (IV'*X)\IV'*Y;
    G_tmp = (IV'*IV)\(IV'*X);
    X_hat = IV*G_tmp;
    b = (X_hat'*X)\(X_hat'*Y);
    
    if nargin == 5
        Yhat = X_pred*b;
        r = Y_pred -Yhat;
    elseif nargin == 4
        Yhat = X_pred*b;
        r = Y - X*b;
    else
        Yhat = X*b;
        r = Y - X*b;
    end

    %IF = (((IV'*X)/n)\(IV.*r)')';
    IF = (((X_hat'*X)/n)\(X_hat.*r)')';
    n = size(r,1);
    Avar = IF'*IF/n;
    SE = sqrt(diag(Avar/n));
    t = b./SE;
    p = 2*(1-cdf('T',abs(t),n)); % need to adjust DF
end