function V = V_stack(M)
% Input: M is Gx1xN


M1 = M(:,:,1);
M2 = M(:,:,2);

G = size(M1,1);

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