/* Stage 1: Find additional ER T */
/* Run a regression like Table 4 to find covariates that significantly affect 
the treatment take-up but not affect outcomes.  */
use data,clear


foreach d in open ever_used account_active5t account_active2t {
	replace `d'_1 = 0 if `d'_1 == .
	replace `d'_2 = 0 if `d'_2 == .
}

tabstat open_1 ever_used_1 account_active5t_1 account_active2t_1 ///
open_2 ever_used_2 account_active5t_2 account_active2t_2 , by(round)

local ind = 1
qui{

local covars sqs1 sqs2 ///
b_account_mobile_money1 b_account_mobile_money2 ///
b_account_mobile_money_m1 b_account_mobile_money_m2 ///
b_age1 b_age2 b_age_m1 b_age_m2 ///
b_education1 b_education2 b_education_m1 b_education_m2 ///
hh_size1 hh_size2 hh_size_m1 hh_size_m2  ///
b_housing_index1 b_housing_index2 b_housing_index_m1 b_housing_index_m2 ///
log_animal_durable1 log_animal_durable2 log_animal_durable_m1 log_animal_durable_m2 ///
b_rosca1 b_rosca2 b_rosca_m1 b_rosca_m2 ///
Z_male Z_female i.round ganga sioport

local cond if Z_one ==1 & round >= 3

reg open_`ind' `covars' `cond'  
est store D1

reg ever_used_`ind' `covars' `cond'  
est store D2

reg account_active2t_`ind' `covars' `cond'  
est store D3

reg account_active5t_`ind' `covars' `cond'  
est store D4

reg exp_bank_dep_usd`ind' `covars' `cond'  
est store Y1

reg bankwithd_usd`ind' `covars' `cond'  
est store Y2

noi est table D1 D2 D3 D4 Y1 Y2, star stat(N r2) b(%5.2f) ///
keep( sqs1 sqs2 ///
b_account_mobile_money1 b_account_mobile_money2 ///
b_age1 b_age2 ///
b_education1 b_education2   ///
hh_size1 hh_size2    ///
b_housing_index1 b_housing_index2   ///
log_animal_durable1 log_animal_durable2   ///
b_rosca1 b_rosca2   ///
Z_male Z_female 4.round 5.round 6.round )
}