mata
mata clear
/* Indices 1{Z=z} */
real matrix idx_fun(z,Z){
	idx = 	(z==1):* 	Z[,1]	:*		Z[,2]  ///
		:+ 	(z==2):*	Z[,1]	:*(1:-	Z[,2]) ///
		:+ 	(z==3):*(1:-Z[,1])	:*		Z[,2]  ///
		:+ 	(z==4):*(1:-Z[,1])	:*(1:-	Z[,2])
	return(idx)
}

/* Pr(Z=z|X) = q_z(X'gamma): q and its derivative */
real matrix q_obs_fun(gam,X){
	q   = normal(X*gam)
	dq  = normalden(X*gam)
	dq1 = dq[,1]:*X
	dq2 = dq[,2]:*X
	return(q,dq1,dq2)
}

/* q_z(X'gamma) as a function of z */
real matrix q_fun(z,Q){
	q1 = Q[,1]
	q2 = Q[,2]		
	
	q = 	(z==1):* 	q1	:*		q2  ///
		:+ 	(z==2):*	q1	:*(1:-	q2) ///
		:+ 	(z==3):*(1:-q1)	:*		q2  ///
		:+ 	(z==4):*(1:-q1)	:*(1:-	q2)
	return(q)
}

/* dq_z(X'gamma)/dgamma as a function of z */
real matrix dq_fun(z,Q){
	q1 = Q[,1]
	q2 = Q[,2]
	dq1 = Q[,3..28]
	dq2 = Q[,29..54]
	
	dq = 	(z==1):*(  dq1:*	q2  ,  	  q1 :* dq2 ) ///
		:+ 	(z==2):*(  dq1:*(1:-q2) ,  	  q1 :*-dq2 ) ///
		:+ 	(z==3):*( -dq1:*	q2  , (1:-q1):* dq2 ) ///
		:+ 	(z==4):*( -dq1:*(1:-q2) , (1:-q1):*-dq2 )
	return(dq)
}

/* omega, and its derivatives */
real matrix w_fun(za,zb,Z,Q){
	w = 	idx_fun(za,Z) :/ q_fun(za,Q) ///
		:-  idx_fun(zb,Z) :/ q_fun(zb,Q)
	return(w)
}
real matrix dw_fun(za,zb,Z,Q){
	dw = 	(-idx_fun(za,Z)) :/ (q_fun(za,Q):^2) :* dq_fun(za,Q) ///
		:-	(-idx_fun(zb,Z)) :/ (q_fun(zb,Q):^2) :* dq_fun(zb,Q)
	return(dw)
}

/* Influence Function for gamma */
real matrix IF_gam_fun(Z,Q){
	G = rows(Z)
	dq1 = Q[,3..28]
	dq2 = Q[,29..54]
	
	r1 = Z[,1]-Q[,1]
	r2 = Z[,2]-Q[,2]	
	sig1 = Q[,1] :* (1:-Q[,1])
	sig2 = Q[,2] :* (1:-Q[,2])
	
	score1 = dq1 :* r1 :/ sig1
	score2 = dq2 :* r2 :/ sig2
	hess1 = (dq1 :/ sig1)'*dq1/ G
	hess2 = (dq2 :/ sig2)'*dq2/ G
	
	IF_gam1 = (pinv(hess1)*score1')'
	IF_gam2 = (pinv(hess2)*score2')'
	IF_gam = IF_gam1, IF_gam2
	return(IF_gam)
}


/* Homogenous variance matrix of moments */
real matrix Homo_S(G, r){
	/* r is the first-stage IV residual */
	S 	= r'*r/G
	Si 	= invsym(S)
	return(Si)
}

real matrix est_2nd(G,YD,w,P,Si){
	Y = YD[,1..2]
	D = YD[,3..4]
	
	/* Compute Second-Stage */
	RwD = J(4,4,0)
	RwY = J(4,1,0)
	for(g=1; g<=G; g++){
		YY = (Y[g,1] \ Y[g,2])
		DD = (D[g,1], D[g,2], 0,0 \ 0,0, D[g,2], D[g,1])
		PP = (P[g,1], P[g,2], 0,0 \ 0,0, P[g,2], P[g,1])
		IV = PP'*Si
		
		RwD = RwD + IV*w[g]*DD
		RwY = RwY + IV*w[g]*YY
	}
	
	b = pinv(RwD)*RwY
	return(b)
}

real matrix var_2nd(G,YD,w,P,Si,b,IF_gam,dw,fs){
	Y = YD[,1..2]
	D = YD[,3..4]
	
	/* rename: IF_b -> Rwe , mat_B_pre -> Re */	
	e1 = Y[,1] - (D[,1], D[,2])*b[1..2]
	e2 = Y[,2] - (D[,2], D[,1])*b[3..4]	
	
	Rwe = J(G,4,0)
	Re	= J(G,4,0)
	B 	= J(4,52,0)

	for(g=1; g<=G; g++){
		PP = (P[g,1], P[g,2], 0 , 0 \ 0, 0, P[g,2], P[g,1])
		IV = PP'*Si
		Rwe[g,] = (IV*w[g]*(e1[g]\e2[g]))'
		Re[g,] 	= (IV*(e1[g]\e2[g]))'
		B 		= B + Re[g,]'*dw[g,]/G
	}
	A 		= Rwe'*Rwe/G
	Ai 		= pinv(A)
	Rwe_c 	= Rwe + IF_gam*B'
	
	/* fs=1 if we need to correct 1st stage error from estimation of gamma */
	if (fs==1){
		V = Ai*(Rwe_c'*Rwe_c/G)*Ai/G
	}
	else{
		V = Ai/G
	}
	return(V)
}

real matrix est(YD,P,r,w,dw,IF_gam,fs){
	G = rows(YD)
	Si 	= Homo_S(G,r)
	b 	= est_2nd(G,YD,w,P,Si)
	V 	= var_2nd(G,YD,w,P,Si,b,IF_gam,dw,fs)
	st_matrix("b", b')
	st_matrix("V", V)
	return(b, V)
}
end

cap program drop est_iv
program est_iv, eclass
syntax varlist (min=0 max=1) [,za(integer 10) zb(integer 10) fs nl]
qui{
	local first = "`fs'" != ""
	local nonlinear = "`nl'" != ""
	
	cap gen iota = 1
	for num 1/2: probit ZX W_* T_* \cap drop PzX \predict PzX \mat gamX = e(b)
	
	putmata YD 	 = (Y1 Y2 D1 D2 D_both), replace
	putmata Z 	 = (Z1 Z2), replace
	putmata X_z  = (W_* T_* iota), replace
	
	mata{
		G 	 	 = rows(Z)
		gam1 	 = st_matrix("gam1")
		gam2 	 = st_matrix("gam2")	
		gam  	 = gam1', gam2'
		
		Q 		 = q_obs_fun(gam, X_z)
		w 		 =  w_fun(`za',`zb',Z,Q)
		dw 	 	 = dw_fun(`za',`zb',Z,Q)
		IF_gam   = IF_gam_fun(Z,Q)
 
		YD_tilde = YD:*w
	}
	getmata (Y_tilde1 Y_tilde2 D_tilde1 D_tilde2 D_tilde_both) = YD_tilde, replace
	
	if `nonlinear' == 0{
	/* Estimate PK (LPM) */
		for any D_tilde1 D_tilde2 D_tilde_both \ num 1/3 : ///
			reg X T_* \ cap drop PY \ predict PY
	}
	else{
	/* Estimate PK (probit) */
		for any D_tilde1 D_tilde2 D_tilde_both \ num 1/3 : ///
			nl (X = normal({xb:T_*}+{b0})), nolog \cap drop PY \predict PY
	}
	
	/* Run 1st stage IV */
	for num 1/2: ivregress 2sls Y_tildeX (D_tilde1 D_tilde2=T_*), r nocon ///
		\cap drop rX_1st \predict rX_1st, resid
	
	putmata r_1st = (r1_1st r2_1st), replace
	putmata P 	  = (P1 P2), replace

	
	mata{
		res = est(YD,P,r_1st,w,dw,IF_gam,`first')
		b = res[,1]
		V = res[,2..5]
		st_matrix("b", b')
		st_matrix("V", V)
	}
	local xlist Direct_female Indirect_female Direct_male Indirect_male
	matrix colnames b = `xlist'
	matrix colnames V = `xlist'
	matrix rownames V = `xlist'

	ereturn post b V
	noi ereturn display
} //qui end	
end