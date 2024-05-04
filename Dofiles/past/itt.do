/* Stage 2: Estimate ITT  */
/* Ren regressions like Table 5, 7 */
/* Add the baseline outcome */
use data, clear
local covars sqs* b_account_mobile_money* b_age* b_educ* 

local covars sqs1 sqs2 ///
b_account_mobile_money1 b_account_mobile_money2 ///
b_account_mobile_money_m1 b_account_mobile_money_m2 ///
b_age1 b_age2 b_age_m1 b_age_m2 ///
b_education1 b_education2 b_education_m1 b_education_m2 


// hh_size1 hh_size2 hh_size_m1 hh_size_m2  ///
// b_housing_index1 b_housing_index2 b_housing_index_m1 b_housing_index_m2 ///
// log_animal_durable1 log_animal_durable2 log_animal_durable_m1 log_animal_durable_m2 ///
// b_rosca1 b_rosca2 b_rosca_m1 b_rosca_m2 


local depvar hasbank

local depvar exp_bank_dep_d
*local depvar exp_bank_dep_usd
*local depvar exp_bank_dep_w1_usd

local depvar bankwithd_d
*local depvar bankwithd_usd
local depvar bankwithd_w1_usd
local depvar exp_total_w1_usd

*local depvar ksh_income_sum_usd
local depvar ksh_income_sum_w1_usd

*local depvar exp_food_w1_usd
*local depvar exp_personal_w1_usd
*local depvar exp_hhgood_w1_usd
*local depvar exp_total_children_w1_usd
  

/* The outcomes of pre-tr period is those in round 1*/
forv i = 1/2{
cap drop x`i'
cap drop Y`i'_pre
cap drop Y`i'_pre_m

qui gen x`i'=`depvar'`i' if round==1
qui egen Y`i'_pre=max(x`i'), by(id`i')
qui gen Y`i'_pre_m=1 if Y`i'_pre ==.
qui replace Y`i'_pre_m=0 if Y`i'_pre !=.
qui replace Y`i'_pre=0 if Y`i'_pre ==.	
}


reg `depvar'1 Z_both Z_male Z_female `covars' Y1_pre i.sioport i.ganga i.round ///
if round >=3 , cluster(id1) r
est store `depvar'1

reg `depvar'2 Z_both Z_male Z_female `covars' Y2_pre i.sioport i.ganga i.round ///
if round >=3 , cluster(id1) r
est store `depvar'2

est table `depvar'1 `depvar'2, keep(Z_both Z_male Z_female) star(0.1 0.05 0.01) stat(N) b(%5.3f)