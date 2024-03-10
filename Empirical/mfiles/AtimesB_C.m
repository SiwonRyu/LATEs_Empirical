function AB = AtimesB_C(A,B)
% A, B: NxKxG
% A(:,:,g)'*B(:,:,g) = (KxN) x (NxK)

    AB_tmp = permute(A,[2,1,4,3]).*permute(B,[4,1,2,3]);
    AB = permute(sum(AB_tmp,2),[1,3,4,2]);    
end