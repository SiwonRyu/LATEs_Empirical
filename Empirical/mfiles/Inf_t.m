function [SE,t,p,Avar] = Inf_t(coef, resid, IF)
    n = size(resid,1);
    Avar = IF'*IF/n;
    SE = sqrt(diag(Avar/n));
    t = coef./SE;
    p = 2*(1-cdf('T',abs(t),n)); % need to adjust DF
end