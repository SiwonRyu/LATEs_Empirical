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
	n_gam = (cols(Q)-2)/2
	q1 = Q[,1]
	q2 = Q[,2]
	dq1 = Q[,3..2+n_gam]
	dq2 = Q[,3+n_gam..2+2*n_gam]
	
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
	n_gam = (cols(Q)-2)/2
	dq1 = Q[,3..2+n_gam]
	dq2 = Q[,3+n_gam..2+2*n_gam]
	
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
	B 	= J(4,cols(IF_gam),0)
	PSiP = J(4,4,0)
	
	for(g=1; g<=G; g++){
		PP = (P[g,1], P[g,2], 0 , 0 \ 0, 0, P[g,2], P[g,1])
		PSiP 	= PSiP + PP'*Si*PP
		IV 		= PP'*Si
		Rwe[g,] = (IV*w[g]*(e1[g]\e2[g]))'
		Re[g,] 	= (IV*(e1[g]\e2[g]))'
		B 		= B + Re[g,]'*dw[g,]/G
	}
	A 		= PSiP/G
	/* A 		= Rwe'*Rwe/G */
	Ai 		= pinv(A)
	Rwe_c 	= Rwe + IF_gam*B'
	
	/* fs=1 if we need to correct 1st stage error from estimation of gamma */
	if (fs==1){
		V = Ai*(Rwe_c'*Rwe_c/G)*Ai/G
	}
	else{
		V = Ai/G
	}
	if (rank(V) < 4){
		V = V + 0.00001*I(4)
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




cap program drop estim_late
program estim_late, eclass
qui{	
	syntax varlist (min = 6) [,cov(varlist) inst(varlist) za(integer 10) zb(integer 10) fs nl]
	tokenize `varlist'
	local Nvars `:word count `varlist''
	
	* Generate temporal variables
	forv unit = 1/2{
		cap drop var_Y`unit'
		cap drop var_D`unit'
		cap drop var_Z`unit'

		local idxY = `unit'
		local idxD = 2+`unit'
		local idxZ = 4+`unit'

		gen var_Y`unit' = ``idxY''
		gen var_D`unit' = ``idxD''
		gen var_Z`unit' = ``idxZ''
	}	
	
	gen var_D_both = var_D1*var_D2
	local first = "`fs'" != ""
	local nonlinear = "`nl'" != ""
	
	cap gen iota = 1
	for num 1/2: probit var_ZX `cov' `inst' \cap drop PzX \predict PzX \mat gamX = e(b)
	
	putmata YD 	 = (var_Y1 var_Y2 var_D1 var_D2 var_D_both), replace
	putmata Z 	 = (var_Z1 var_Z2), replace
	putmata X_z  = (`cov' `inst' iota), replace
	
	mata{
		G 	 	 = rows(Z)
 		gam1 	 = st_matrix("gam1")
 		gam2 	 = st_matrix("gam2")	
 		gam  	 = gam1', gam2'
 		ngam 	 = length(gam)
		
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
			reg X `inst' \ cap drop PY \ predict PY
	}
	else{
	/* Estimate PK (probit) */
		for any D_tilde1 D_tilde2 D_tilde_both \ num 1/3 : ///
			nl (X = normal({xb:`inst'}+{b0})), nolog \cap drop PY \predict PY
	}
	
	/* Run 1st stage IV */
	for num 1/2: ivregress 2sls Y_tildeX (D_tilde1 D_tilde2=`inst'), r nocon ///
		\cap drop rX_1st \predict rX_1st, resid
	
	putmata r_1st = (r1_1st r2_1st), replace
	putmata P 	  = (P1 P2), replace
	
	
	mata{
		res = est(YD,P,r_1st,w,dw,IF_gam,`first')
		b = res[,1]
		V = res[,2..5]
		st_matrix("b", b')
		st_matrix("V", V)
		st_matrix("G", G)
	}
	local xlist Direct_female Indirect_female Direct_male Indirect_male
	matrix colnames b = `xlist'
	matrix colnames V = `xlist'
	matrix rownames V = `xlist'

	
	ereturn post b V
	noi ereturn display
	noi di "Number of observations used = " G[1,1]
	
	drop var_* *tilde* *1st P* iota
} //qui end	
end


cap program drop estim_iv
program estim_iv, eclass
qui{
	syntax varlist (min = 6) [,cov(varlist) inst(varlist)]
	tokenize `varlist'
	local Nvars `:word count `varlist''
	
	* Generate temporal variables
	forv unit = 1/2{
		cap drop var_Y`unit'
		cap drop var_D`unit'
		cap drop var_Z`unit'

		local idxY = `unit'
		local idxD = 2+`unit'
		local idxZ = 4+`unit'
		
		gen var_Y`unit' = ``idxY''
		gen var_D`unit' = ``idxD''
		gen var_Z`unit' = ``idxZ''
	}
	
	ivregress 2sls var_Y1 (i.var_D1##i.var_D2 = i.var_Z1##i.var_Z2) `cov' `inst',r
	est store iv1
	local iv1_dir_coef = _b[1.var_D1]
	local iv1_dir_se = _se[1.var_D1]
	local iv1_ind_coef = _b[1.var_D2]
	local iv1_ind_se = _se[1.var_D2]
	local N1 = e(N)

	ivregress 2sls var_Y2 (i.var_D1##i.var_D2 = i.var_Z1##i.var_Z2)  `cov' `inst',r
	est store iv2
	local iv2_dir_coef = _b[1.var_D2]
	local iv2_dir_se = _se[1.var_D2]
	local iv2_ind_coef = _b[1.var_D1]
	local iv2_ind_se = _se[1.var_D1]
	local N2 = e(N)

	mat b_iv = J(1,4,0)
	mat V_iv = J(4,4,0)
	mat b_iv[1,1] = `iv1_dir_coef'
	mat b_iv[1,2] = `iv2_ind_coef'
	mat b_iv[1,3] = `iv1_ind_coef'
	mat b_iv[1,4] = `iv2_dir_coef' 
	mat V_iv[1,1] = `iv1_dir_se'^2
	mat V_iv[2,2] = `iv2_ind_se'^2
	mat V_iv[3,3] = `iv1_ind_se'^2
	mat V_iv[4,4] = `iv2_dir_se'^2
	matlist b_iv
	matlist V_iv

	local xlist Direct_female Indirect_male Indirect_female Direct_male
	matrix colnames b_iv = `xlist'
	matrix colnames V_iv = `xlist'
	matrix rownames V_iv = `xlist'

	ereturn post b_iv V_iv
	noi ereturn display
	noi di "Number of observations used = " `N1' "/" `N2'
	drop var_*
} //qui end	
end