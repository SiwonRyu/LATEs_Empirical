function [b, r, Yhat, IF, SE, t, p, Avar, X_hat] = IVe(Y,X,IV,X_pred,Y_pred)
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
    [SE,t,p,Avar] = Inf_t(b,r,IF);
end