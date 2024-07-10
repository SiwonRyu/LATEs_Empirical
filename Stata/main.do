set more off
clear all
macro drop _all

cd "`c(pwd)'"


/*******************************************************************************
	Data_from the original replication package
*******************************************************************************/
qui do "Dofiles\generate_data.do"
use data, clear


* Outcome variables
su exp_bank_dep_d1 exp_bank_dep_w1_usd1 bankwithd_d1 bankwithd_w1_usd1 amtgavesp_d1 amtgavesp_w1_usd1
su exp_bank_dep_d2 exp_bank_dep_w1_usd2 bankwithd_d2 bankwithd_w1_usd2 amtgavesp_d2 amtgavesp_w1_usd2
 
* Set take-up varaible (D)
qui{
	for num 1/2: gen DX = openX // Takeup: open
	*for num 1/2: gen DX = hasbankX

	gen  D_both = D1*D2
	gen  D_male = (1-D1)*D2
	gen  D_female = D1*(1-D2)
	gen  D_none = (1-D1)*(1-D2)
	egen D_one = rmax(D1 D2)

	gen  Z_both = Z1*Z2
	gen  Z_male = (1-Z1)*Z2
	gen  Z_female = Z1*(1-Z2)
	gen  Z_none = (1-Z1)*(1-Z2)
	egen Z_one = rmax(Z1 Z2)

	// Verify with Table 3
	su D_one D_female D_male D_both if hh_faim_id != 4357 & Z_female == 1
	su D_one D_female D_male D_both if hh_faim_id != 4357 & Z_male == 1
	su D_one D_female D_male D_both if hh_faim_id != 4357 & Z_both == 1

	// Treatment Categorical Variables
	gen Z_cat = Z1*Z2 + 2*Z1*(1-Z2) + 3*(1-Z1)*Z2 + 4*(1-Z1)*(1-Z2)
	gen D_cat = D1*D2 + 2*D1*(1-D2) + 3*(1-D1)*D2 + 4*(1-D1)*(1-D2)

	label define TR_CAT ///
	1 "Both treated" 2 "Female treated" 3 "Male treated" 4 "No one treated"
	label define TK_CAT ///
	1 "Both take-up" 2 "Female take-up" 3 "Male take-up" 4 "No one take-up" 
	label values Z_cat TR_CAT
	label values D_cat TK_CAT
}
tab Z_cat D_cat if round == 3
tab Z_cat D1 if round == 3
tab Z_cat D2 if round == 3


* Set Covariates (T, W)
// Unit-level variables
egen hh_size = rowmax(hh_size1 hh_size2)
forv i = 1/2{
	local W_`i' 	b_account_mobile_money`i' b_age`i'  b_education`i' b_rosca`i'		
	local T_`i' 	sqs`i'  
	local nW_`i' : word count `W_`i''
	local nT_`i' : word count `T_`i''
	
	for any `W_`i'' \ num 1/`nW_`i'' : cap drop W_`i'Y \ gen W_`i'Y = X
	for any `T_`i'' \ num 1/`nT_`i'' : cap drop T_`i'Y \ gen T_`i'Y = X
}
// Interaction Terms
for num 1/`nW_1' : cap drop W_intX \ gen W_intX = W_1X*W_2X
for num 1/`nT_1' : cap drop T_intX \ gen T_intX = T_1X*T_2X

// Group-level variables
local W_g ganga sioport hh_size
local T_g h_index log_ani  
local nW_g : word count `W_g'
local nT_g : word count `T_g'

for any `W_g' \ num 1/`nW_g' : cap drop W_gY \ gen W_gY = X
for any `T_g' \ num 1/`nT_g' : cap drop T_gY \ gen T_gY = X

// Number of coefficients for estimating P(Z)
local N_gam =  `nW_g'+ `nT_g'+ 2*`nW_1'+ 2*`nW_2'+ `nT_1'+ `nT_2'


/*******************************************************************************
	Find additional ER T
Run a regression like Table 4 to find covariates that significantly affect 
the treatment take-up but not affect outcomes.
*******************************************************************************/
local Ylist exp_bank_dep_d exp_bank_dep_w1_usd bankwithd_d bankwithd_w1_usd amtgavesp_d amtgavesp_w1_usd

reg D1 T* W* 
est store regD1
reg D2 T* W* 
est store regD2
reg D_both T* W* 
est store regDb

local j = 0
foreach Y in `Ylist'{
	forv i = 1/2{
		cap drop x`i'
		cap drop `Y'`i'_b
		gen  x`i' = `Y'`i' if round==1
		egen `Y'`i'_b=max(x`i'), by(id`i') 
		drop x`i'
	}


	local j = `j'+1
	reg `Y'1 T* W* `Y'1_b
	est store regY1_`j'

	reg `Y'2 T* W* `Y'2_b
	est store regY2_`j'
}
est table regD1 regD2 regDb regY1_1 regY2_1 regY1_2 regY2_2, b(%5.3f) star stat(N)
est table regD1 regD2 regDb regY1_3 regY2_3 regY1_4 regY2_4, b(%5.3f) star stat(N)

est table regD1 regD2 regDb regY1_1 regY2_1 regY1_3 regY2_3, b(%5.3f) star stat(N)
est table regD1 regD2 regDb regY1_1 regY2_1 regY1_3 regY2_3, b(%5.3f)  se stat(N)


cap erase ET3.xls
cap erase ET3.txt
foreach ests in regD1 regD2 regDb regY1_1 regY2_1 regY1_3 regY2_3{
	est restore `ests'
	outreg2 using ET3.xls, stats(coef se pval) dec(3) append noaster alpha(0.001, 0.01, 0.05) keep(T*)
}


/*******************************************************************************
	Data Export in Excel xlsx format
*******************************************************************************/
global depvar bankwithd_d
forv i = 1/2{
	cap drop Y`i'
	* Dependent variable as Y
	gen  Y`i' = ${depvar}`i'
	
	* Dependent variable at initial period as Y_b
	cap drop Y`i'_1
	cap drop Y`i'_b
	gen  Y`i'_1 = Y`i' if round==1
	egen Y`i'_b =max(Y`i'_1), by(id`i')
	drop Y`i'_1
}

keep if round >= 3 & round <=6
cap drop nmis
egen nmis=rmiss(Y* T* W*)
tab nmis
keep if nmis == 0
drop nmis
do "Dofiles\export_to_excel.do"
save data_analysis, replace


/*******************************************************************************
	Description of Covariates
*******************************************************************************/
su W_1* 
su W_2*
su T_1* 
su T_2*
su T_g* T_int*
su W_g* W_int*


/*******************************************************************************
	Estimate ITT effects, compare to Table 5-7
*******************************************************************************/
qui{
xtset round hh_faim_id
xtreg Y1 Z1 Y1_b T_* W_*
est store ITT_ind1
xtreg Y1 Z1 Z2 Z_both Y1_b T_* W_*
est store ITT_inf1
xtreg Y2 Z2 Y2_b T_* W_*
est store ITT_ind2
xtreg Y2 Z1 Z2 Z_both Y2_b T_* W_*
est store ITT_inf2
}
est table ITT_ind1 ITT_inf1 ITT_ind2 ITT_inf2, keep(Z1 Z2 Z_both) star b(%5.3f)


/*******************************************************************************
	Estimation
estim_latt: IV regression by using additional exclusion restrictions (T).
	
estim_iv: IV regression proposed in Vazquez-Bare (2022). For unit i, coef. of Di 
is direct when i is complier and coef. of Dj is the indirect when j is complier
*******************************************************************************/
qui do "Dofiles\def_estim.do"

use data_analysis, clear
xtset hh_faim round

*Extensive: exp_bank_dep_d bankwithd_d 
*Intensive: exp_bank_dep_w1_usd bankwithd_w1_usd 

local depvar exp_bank_dep_d
*local depvar bankwithd_d
preserve
drop if `depvar'1 == .
drop if `depvar'2 == .
estim_late 	`depvar'1 `depvar'2 D1 D2 Z1 Z2, cov(W_*) inst(T_*) za(2) zb(4) fs 
estim_late 	`depvar'1 `depvar'2 D1 D2 Z1 Z2, cov(W_*) inst(T_*) za(3) zb(4) fs 
estim_iv 	`depvar'1 `depvar'2 D1 D2 Z1 Z2, cov(W_*) inst(T_*)
restore

local depvar exp_bank_dep_d
*local depvar bankwithd_d
preserve
drop if `depvar'1 == .
drop if `depvar'2 == .
estim_late 	`depvar'1 `depvar'2 D1 D2 Z1 Z2, cov(W_*) inst(T_*) za(2) zb(4) fs nl
estim_late 	`depvar'1 `depvar'2 D1 D2 Z1 Z2, cov(W_*) inst(T_*) za(3) zb(4) fs nl
estim_iv 	`depvar'1 `depvar'2 D1 D2 Z1 Z2, cov(W_*) inst(T_*)
restore
