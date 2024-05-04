cd "C:\rsw\Replication Datasets\Kenya Savings"
use data, clear


/*******************************************************************************
	Set outcome variable (Y)
*******************************************************************************/
qui{
local depvar exp_bank_dep_d
*local depvar exp_bank_dep_w1_usd
*local depvar bankwithd_d
*local depvar bankwithd_w1_usd
*local depvar amtgavesp_usd
*local depvar amtgavesp_d
*local depvar amtgavesp_w1_usd

// The outcomes of pre-tr period is those in round 1
forv i = 1/2{
	cap drop Y`i'
	cap drop x`i'
	cap drop Y`i'_pre
	cap drop Y`i'_pre_m

	gen  Y`i' = `depvar'`i'
	gen  x`i'=`depvar'`i' if round==1
	egen Y`i'_pre=max(x`i'), by(id`i')
	gen  Y`i'_pre_m=1 if Y`i'_pre ==.
	replace Y`i'_pre_m=0 if Y`i'_pre !=.
	replace Y`i'_pre=0 if Y`i'_pre ==.	
}

// Drop all missings
keep if b_age_m1 == 0 & b_age_m2 == 0 ///
& b_education_m1 == 0 & b_education_m2 == 0 ///
& h_index_m == 0 & log_ani_m == 0 ///
& b_rosca_m1 == 0 & b_rosca_m2 == 0 ///
& hh_size_m1 == 0 & hh_size_m2 == 0 ///
& Y1_pre_m == 0 & Y2_pre_m == 0
}
tabstat hh_faim_id, statistics( count ) by(round) 



/*******************************************************************************
	Set take-up varaible (D)
*******************************************************************************/
qui{
// Takeup: open
local take_up open
gen D1 = `take_up'1
gen D2 = `take_up'2
replace D1 = 0 if D1 == .
replace D2 = 0 if D2 == .

// Takeup: hasbank
// local take_up hasbank
// gen D1 = `take_up'1
// gen D2 = `take_up'2
// replace D1 = 1 if open1 == 1
// replace D2 = 1 if open2 == 1
// replace D1 = 0 if D1 == .
// replace D2 = 0 if D2 == .

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



/*******************************************************************************
	Description of Outcome
*******************************************************************************/
gen post = round >= 2

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
	Set Covariates
*******************************************************************************/
// Unit-level variables
forv i = 1/2{
	local W_`i' ///
	b_account_mobile_money`i' b_age`i'  b_education`i' ///
	b_rosca`i' ksh_income_sum_w1_usd`i'
		
	local T_`i' ///
	sqs`i' hh_size`i' 
	
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
ganga sioport

local T_g ///
h_index log_ani

local nW_g : word count `W_g'
local nT_g : word count `T_g'

for any `W_g' \ num 1/`nW_g' : cap drop W_gY \ gen W_gY = X
for any `T_g' \ num 1/`nT_g' : cap drop T_gY \ gen T_gY = X





/* Stage 1: Find additional ER T */
/* Run a regression like Table 4 to find covariates that significantly affect 
the treatment take-up but not affect outcomes.  */
*keep if round >= 2
reg D1 T* W*,r
est store regD1
reg D2 T* W*,r
est store regD2
reg D_both T* W*,r
est store regDb

reg Y1 T* W* Y1_pre,r
est store regY1
reg Y2 T* W* Y2_pre,r
est store regY2

est table regD1 regD2 regDb regY1 regY2, b(%5.3f) star stat(N)








/* Stage 2: Estimate ITT  */
/* Ren regressions like Table 5, 7 */
/* Add the baseline outcome */
use HH_data, clear
local covars sqs* b_account_mobile_money* b_age* b_educ* 

local depvar hasbank

local depvar exp_bank_dep_d
*local depvar exp_bank_dep_usd
*local depvar exp_bank_dep_w1_usd

*local depvar bankwithd_d
*local depvar bankwithd_usd
*local depvar bankwithd_w1_usd
*local depvar exp_total_w1_usd

*local depvar ksh_income_sum_usd
*local depvar ksh_income_sum_w1_usd

*local depvar exp_food_w1_usd
*local depvar exp_personal_w1_usd
*local depvar exp_hhgood_w1_usd
*local depvar exp_total_children_w1_usd
  
/* The outcomes of pre-tr period is those in round 1*/
forv i = 1/2{
cap drop x`i'
cap drop Y`i'_pre
cap drop Y`i'_pre_m

qui gen x`i'=`depvar'1 if round==1
qui egen Y`i'_pre=max(x`i'), by(id`i')
qui gen Y`i'_pre_m=1 if Y`i'_pre ==.
qui replace Y`i'_pre_m=0 if Y`i'_pre !=.
qui replace Y`i'_pre=0 if Y`i'_pre ==.	
}



reg `depvar'1 Z_both Z_male Z_female `covars' Y1_pre i.sioport i.ganga, cluster(id1) r
est store `depvar'1
reg `depvar'2 Z_both Z_male Z_female `covars' Y2_pre i.sioport i.ganga, cluster(id2) r
est store `depvar'2

est table `depvar'1 `depvar'2, keep(Z_both Z_male Z_female) star(0.1 0.05 0.01) stat(N) b(%5.3f)



/* Stage 3: Estimate Compliance distribtuions */
reg D1 sqs* b_housing_index* log_animal_durable* b_rosca* i.round
predict PD1
reg D2 sqs* b_housing_index* log_animal_durable* b_rosca* i.round
predict PD2
reg D_both sqs* b_housing_index* log_animal_durable* b_rosca* i.round
predict PD12







gen omega = 1
gen Ytmp1 = `depvar'1*omega
gen Ytmp2 = `depvar'2*omega
gen D1t = D1*omega
gen D2t = D1*omega
gen D12t = D1*D2*omega


/* Stage 4-1: Estimate propensity score and weight */
local depvar exp_bank_dep_d
*local depvar exp_bank_dep_usd
*local depvar exp_bank_dep_w1_usd

local covars sqs* b_account_mobile_money* b_age* b_educ* hh_size* ///
b_housing_index* log_animal_durable* b_rosca* 

/* The outcomes of pre-tr period is those in round 1*/
forv i = 1/2{
cap drop x`i'
cap drop Y`i'_pre
cap drop Y`i'_pre_m

qui gen x`i'=`depvar'1 if round==1
qui egen Y`i'_pre=max(x`i'), by(id`i')
qui gen Y`i'_pre_m=1 if Y`i'_pre ==.
qui replace Y`i'_pre_m=0 if Y`i'_pre !=.
qui replace Y`i'_pre=0 if Y`i'_pre ==.	
}

cap drop PZ1
cap drop PZ2
reg Z1 `covars' i.ganga i.sioport Y1_pre
predict PZ1
reg Z2 `covars' i.ganga i.sioport Y2_pre
predict PZ2

su PZ1 PZ2



/* Stage 4-2: Estimate 1st Stage IV */
local ind 1
reg `depvar'1 D1 D2 D_both
reg `depvar'2 D1 D2 D_both


ivregress 2sls Ytmp1 (D1t D2t D12t = PD1 PD2 PD12) ,nocon
ivregress 2sls Ytmp2 (D1t D2t D12t = PD1 PD2 PD12) ,nocon

/* Stage 5: Estimate 2nd Stage IV */

