set more off
clear all
macro drop _all

global baseroot "E:\Dropbox\Research\Projects\Topic 2 LATET (3YP)\Replication Package\Empirical Illustration\Stata"
cd "$baseroot"

/*******************************************************************************
	Data_from the original replication package
*******************************************************************************/
use faim_data.dta, clear
do "Dofiles\generate_data.do"


/*******************************************************************************
	Data pre-processing: Set outcome variable (Y)
*******************************************************************************/
use data, clear
su exp_bank_dep_d1 exp_bank_dep_w1_usd1 bankwithd_d1 bankwithd_w1_usd1 amtgavesp_d1 amtgavesp_w1_usd1
su exp_bank_dep_d2 exp_bank_dep_w1_usd2 bankwithd_d2 bankwithd_w1_usd2 amtgavesp_d2 amtgavesp_w1_usd2

cap drop nmis
egen nmis=rmiss(exp_bank_dep_d* exp_bank_dep_w1_usd* bankwithd_d* bankwithd_w1_usd* amtgavesp_d* amtgavesp_w1_usd*)
tab nmis
keep if nmis == 0
drop nmis


*global depvar exp_bank_dep_d
global depvar bankwithd_d


*global depvar exp_bank_dep_w1_usd
*global depvar bankwithd_w1_usd
*global depvar amtgavesp_usd
*global depvar amtgavesp_d
*global depvar amtgavesp_w1_usd
*global depvar transfHH_received_remit_d1 
*global depvar transfHH_sent_shar_d
 
qui{
// The outcomes of pre-tr period is those in round 1
forv i = 1/2{
	cap drop Y`i'
	cap drop x`i'
	cap drop Y`i'_pre
	gen  Y`i' = ${depvar}`i'
	gen  x`i' = ${depvar}`i' if round==1
	egen Y`i'_pre=max(x`i'), by(id`i')	
}

reg Y1 Y1_pre b_age* b_educ* hh_size* h_index log_ani Y1_pre Y2_pre
// Drop all missings
keep if e(sample)
tabstat hh_faim_id, statistics( count ) by(round) 
}


/*******************************************************************************
	Data pre-processing: Set take-up varaible (D)
*******************************************************************************/
qui{
// Takeup: open
for num 1/2: gen DX = openX
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
tab Z_cat D_cat

tab Z_cat D1 if round == 3
tab Z_cat D2 if round == 3



tab round, gen(rr)
/*******************************************************************************
	Data pre-processing: Set Covariates
*******************************************************************************/
// Unit-level variables
egen hh_size = rowmax(hh_size1 hh_size2)
forv i = 1/2{
	local W_`i' ///
	b_account_mobile_money`i' b_age`i'  b_education`i' ///
	b_rosca`i'
	*ksh_income_sum_w1_usd`i'
		
	local T_`i' ///
	sqs`i'  
	
	local nW_`i' : word count `W_`i''
	local nT_`i' : word count `T_`i''
	
	for any `W_`i'' \ num 1/`nW_`i'' : cap drop W_`i'Y \ gen W_`i'Y = X
	for any `T_`i'' \ num 1/`nT_`i'' : cap drop T_`i'Y \ gen T_`i'Y = X
}
// Interaction Terms
for num 1/`nW_1' : cap drop W_intX \ gen W_intX = W_1X*W_2X
for num 1/`nT_1' : cap drop T_intX \ gen T_intX = T_1X*T_2X

// Group-level variables
local W_g ///
ganga sioport hh_size
*hh_size

local T_g ///
h_index log_ani  

local nW_g : word count `W_g'
local nT_g : word count `T_g'

for any `W_g' \ num 1/`nW_g' : cap drop W_gY \ gen W_gY = X
for any `T_g' \ num 1/`nT_g' : cap drop T_gY \ gen T_gY = X

local N_gam =  `nW_g'+ `nT_g'+ 2*`nW_1'+ 2*`nW_2'+ `nT_1'+ `nT_2'



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
		cap drop `Y'`i'_pre
		gen  x`i' = `Y'`i' if round==1
		egen `Y'`i'_pre=max(x`i'), by(id`i') 
		drop x`i'
	}


	local j = `j'+1
	reg `Y'1 T* W* `Y'1_pre 
	est store regY1_`j'

	reg `Y'2 T* W* `Y'2_pre 
	est store regY2_`j'
}
est table regD1 regD2 regDb regY1_1 regY2_1 regY1_2 regY2_2, b(%5.3f) star stat(N)
est table regD1 regD2 regDb regY1_3 regY2_3 regY1_4 regY2_4, b(%5.3f) star stat(N)
*est table regD1 regD2 regDb regY1_5 regY2_5 regY1_6 regY2_6, b(%5.3f) star stat(N)

est table regD1 regD2 regDb regY1_1 regY2_1 regY1_3 regY2_3, b(%5.3f) star stat(N)
est table regD1 regD2 regDb regY1_1 regY2_1 regY1_3 regY2_3, b(%5.3f)  se stat(N)



gen post = round >= 3 & round <=6

/*******************************************************************************
	Data pre-processing: Description of Outcome
*******************************************************************************/

// preserve
// collapse Y1 Y2, by(Z_cat post)
// tw (connected Y1 post if Z_cat == 1, sort mcolor(black) lcolor(black)) ///
// (connected Y1 post if Z_cat == 2, sort mcolor(blue) lcolor(blue)) ///
// (connected Y1 post if Z_cat == 3, sort mcolor(red) lcolor(red)) ///
// (connected Y1 post if Z_cat == 4, sort mcolor(black) lcolor(black) lp(dash))  ///
// , legend(order( 1 "Both treated" 2 "Female tretaed" 3 "Male treated" 4 "No one treated") rows(2) region(lcolor(%9)) position(6) ) xlabel(0  "pre" 1 "post") name(fig1, replace)
//
// tw (connected Y2 post if Z_cat == 1, sort mcolor(black) lcolor(black)) ///
// (connected Y2 post if Z_cat == 2, sort mcolor(blue) lcolor(blue)) ///
// (connected Y2 post if Z_cat == 3, sort mcolor(red) lcolor(red)) ///
// (connected Y2 post if Z_cat == 4, sort mcolor(black) lcolor(black) lp(dash))  ///
// , legend(order( 1 "Both treated" 2 "Female tretaed" 3 "Male treated" 4 "No one treated") rows(2) region(lcolor(%9)) position(6) ) xlabel(0  "pre" 1 "post") name(fig2, replace)
// restore
//
//
// preserve
// collapse Y1 Y2, by(D_cat post)
// tw (connected Y1 post if D_cat == 1, sort mcolor(black) lcolor(black)) ///
// (connected Y1 post if D_cat == 2, sort mcolor(blue) lcolor(blue)) ///
// (connected Y1 post if D_cat == 3, sort mcolor(red) lcolor(red)) ///
// (connected Y1 post if D_cat == 4, sort mcolor(black) lcolor(black) lp(dash))  ///
// , legend(order( 1 "Both take" 2 "Female take" 3 "Male take" 4 "No one take") rows(2) region(lcolor(%9)) position(6) ) xlabel(0  "pre" 1 "post") name(fig3, replace)
//
// tw (connected Y2 post if D_cat == 1, sort mcolor(black) lcolor(black)) ///
// (connected Y2 post if D_cat == 2, sort mcolor(blue) lcolor(blue)) ///
// (connected Y2 post if D_cat == 3, sort mcolor(red) lcolor(red)) ///
// (connected Y2 post if D_cat == 4, sort mcolor(black) lcolor(black) lp(dash))  ///
// , legend(order( 1 "Both take" 2 "Female take" 3 "Male take" 4 "No one take") rows(2) region(lcolor(%9)) position(6) ) xlabel(0  "pre" 1 "post") name(fig4, replace)
// restore



/*******************************************************************************
	Data Export in Excel xlsx format
*******************************************************************************/
keep if round >= 3 & round <=6

cap drop nmis
egen nmis=rmiss(Y* T* W*)
tab nmis
keep if nmis == 0
drop nmis
do "Dofiles\export_to_excel.do"




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
	Find additional ER T
Run a regression like Table 4 to find covariates that significantly affect 
the treatment take-up but not affect outcomes.
*******************************************************************************/

*keep if round >= 2






save data_analysis, replace



/*******************************************************************************
	Estimation
*******************************************************************************/
do "Dofiles\def_est_iv.do"


use data_analysis, clear
xtset hh_faim round
drop if Y1 == .
drop if Y2 == .
// gen dy1 = d.Y1
// gen dy2 = d.Y2
// drop Y1 Y2
// drop if dy1 == .
// drop if dy2 == .
// ren dy1 Y1
// ren dy2 Y2

*replace Y1 = log(Y1+1)
*replace Y2 = log(Y2+1)
est_iv Y1 ,za(2) zb(4) fs 
est_iv Y1 ,za(3) zb(4) fs 





/*******************************************************************************
	Vazquez (2022) IV regression 
for unit i, 
coef of Di is direct when i is complier
coef of Dj is the indirect when j is complier
*******************************************************************************/
qui{
ivregress 2sls Y1 (i.D1##i.D2 = i.Z1##i.Z2) T_* W_*,r 
est store VZ1
local VZ1_dir_coef = _b[1.D1]
local VZ1_dir_se = _se[1.D1]
local VZ1_ind_coef = _b[1.D2]
local VZ1_ind_se = _se[1.D2]

ivregress 2sls Y2 (i.D1##i.D2 = i.Z1##i.Z2)  T_* W_*,r 
est store VZ2
local VZ2_dir_coef = _b[1.D2]
local VZ2_dir_se = _se[1.D2]
local VZ2_ind_coef = _b[1.D1]
local VZ2_ind_se = _se[1.D1]

mat b_VZ = J(1,4,0)
mat V_VZ = J(4,4,0)
mat b_VZ[1,1] = `VZ1_dir_coef'
mat b_VZ[1,2] = `VZ2_ind_coef'
mat b_VZ[1,3] = `VZ1_ind_coef'
mat b_VZ[1,4] = `VZ2_dir_coef' 
mat V_VZ[1,1] = `VZ1_dir_se'^2
mat V_VZ[2,2] = `VZ2_ind_se'^2
mat V_VZ[3,3] = `VZ1_ind_se'^2
mat V_VZ[4,4] = `VZ2_dir_se'^2
matlist b_VZ
matlist V_VZ

local xlist Direct_female Indirect_male Indirect_female Direct_male
matrix colnames b_VZ = `xlist'
matrix colnames V_VZ = `xlist'
matrix rownames V_VZ = `xlist'

ereturn post b_VZ V_VZ
noi ereturn display
}
	


	


/*******************************************************************************
	Estimate ITT effects, compare to Table 5-7
*******************************************************************************/
qui{
xtset round hh_faim_id
qui xtreg Y1 Z1 Y1_pre T_* W_*
est store ITT_ind1
qui xtreg Y1 Z1 Z2 Z_both Y1_pre T_* W_*
est store ITT_inf1
qui xtreg Y2 Z2 Y2_pre T_* W_*
est store ITT_ind2
qui xtreg Y2 Z1 Z2 Z_both Y2_pre T_* W_*
est store ITT_inf2
}
est table ITT_ind1 ITT_inf1 ITT_ind2 ITT_inf2, keep(Z1 Z2 Z_both) star b(%5.3f)
