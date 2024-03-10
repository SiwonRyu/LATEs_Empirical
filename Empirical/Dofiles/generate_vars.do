// Expenditures on bank deposits
/*
hh: household level (Sum of both spouses)

preserve
	use "replication\data_tmp", clear
	egen bank_dep_tmp = total(exp_bank_dep), by(hh_faim_id round)
	gen dd =  bank_dep_tmp - exp_bank_dep_hh
	su bank_dep_tmp exp_bank_dep_hh dd
	reg bank_dep_tmp exp_bank_dep_hh
	*tw scatter bank_dep_tmp exp_bank_dep_hh
restore

_d: dummies for them. ==1 if nonzero.
*/

*use "data_tmp2", clear


sort hh_faim_id round faim_id
foreach var in b_age b_education b_hyperbolic b_write_swahili b_rosca {
	gen `var'_spouse=`var'[_n+1] if female==0  & hh_faim_id==hh_faim_id[_n+1] & round==round[_n+1]
	replace `var'_spouse=`var'[_n-1] if female==1  & hh_faim_id==hh_faim_id[_n-1] & round==round[_n-1]
	
	gen `var'_male=`var' if female==0
	replace `var'_male=`var'_spouse if female==1
	gen `var'_female=`var' if female==1
	replace `var'_female=`var'_spouse if female==0
}

*fix entry error;
replace b_age_female=. if b_age_female==105 | b_age_female<16

foreach var in b_has_mobile_phone b_account_mobile_money {
	egen `var'_hh=total(`var'), by(hh_faim round) missing
	replace `var'_hh=1 if `var'_hh==2
}

/* Here they use exchange rate as 80 Ksh/USD */
gen usd_income_sale_animal_hh_w1=ksh_income_sale_animal_hh/80
gen usd_income_sum_hh=ksh_income_sum_hh/80
gen b_animal_durable_usd=b_animal_durable/80
sum b_animal_durable_usd if round==1, d
gen b_animal_durable_usd_w1=b_animal_durable_usd
replace b_animal_durable_usd_w1=r(p99) if b_animal_durable_usd>r(p99) & b_animal_durable_usd!=.


replace exp_bank_dep_hh_d=0 	if hasbank_hh==0 & exp_bank_dep_hh_d==.
replace exp_bank_dep_hh_w1=0 	if hasbank_hh==0 & exp_bank_dep_hh_w1==.


/* Convert to USD exchange rate: 80 Ksh/USD
bank deposit / withdrawal / rosca deposit 
mobile money saving / animal/ savgins at home
G_inputcost_hh_w1 (?)
tot_buy_biz_hh_w1 (?)
ksh_income_sum_hh_w1 (income) 
exp_total_hh_w1 (expenditure)
exp_food_hh_w1 (food exp)
exp_personal_hh_w1 (personal exp)
exp_hhgood_hh_w1 (household goods exp)
exp_total_children_hh_w1 (exp for children) */

// HH level
foreach var in ///
	exp_bank_dep_hh_w1 ///
	bankwithd_hh_w1 ///
	exp_rosca_dep_hh_w1 ///
	mob_money_sav_amt_hh_w1 ///
	animal_invest_hh_w1 ///
	exp_savings_home_hh_w1 ///
	exp_bank_dep_hh ///
	bankwithd_hh /// 
	exp_rosca_dep_hh ///
	mob_money_sav_amt_hh ///
	animal_invest_hh ///
	exp_savings_home_hh ///
	G_inputcost_hh_w1 ///
	tot_buy_biz_hh_w1 ///
	ksh_income_sum_hh_w1 ///
	ksh_income_sum_hh ///
	exp_total_hh_w1 ///
	exp_food_hh_w1 ///
	exp_personal_hh_w1 ///
	exp_hhgood_hh_w1 ///
	exp_total_children_hh_w1 {
	gen `var'_usd=`var'/80
}

// Ind level
foreach var in ///
	exp_bank_dep ///
	exp_bank_dep_w1 ///
	bankwithd ///
	bankwithd_w1 ///
	ksh_income_sum ///
	ksh_income_sum_w1 ///
	exp_total_w1 ///
	exp_food_w1 ///
	exp_personal_w1 ///
	exp_hhgood_w1 ///
	exp_total_children_w1 ///
	amtgavesp amtgavesp_w1 {
	gen `var'_usd=`var'/80
}

 


/* Generate extensive margin response */
foreach var in exp_bank_dep bankwithd amtgavesp{
	cap drop `var'_d
	gen `var'_d = 1 if `var' > 0
	replace `var'_d = 0 if `var' == 0 | `var' == .
	tabstat `var' , by(`var'_d)
	su `var' `var'_d	
}
ren exp_bank_dep_hh_d exp_bank_dep_d_hh


// Verify: Extensive Margins
/* hasbank: This is just indicator of having ANY account */
local varn  hasbank
local varn_hh  hasbank_hh
preserve		
	egen x_tmp = total(`varn'), by(hh_faim_id round)
	replace x_tmp = 1 if x_tmp == 2
	gen dd =  x_tmp - `varn_hh'
	reg x_tmp `varn_hh'
	*tw scatter bank_dep_tmp exp_bank_dep_hh
	su x_tmp `varn_hh'
	su x_tmp `varn_hh' if e(sample)
restore

/* Deposit EMR: This is just indicator of having ANY account */
local varn  exp_bank_dep_d
local varn_hh  exp_bank_dep_d_hh
preserve		
	egen x_tmp = total(`varn'), by(hh_faim_id round)
	replace x_tmp = 1 if x_tmp == 2
	gen dd =  x_tmp - `varn_hh'
	reg x_tmp `varn_hh'
	*tw scatter bank_dep_tmp exp_bank_dep_hh
	su x_tmp `varn_hh'
	su x_tmp `varn_hh' if e(sample)
restore

/* Widthdrawal EMR: This is just indicator of having ANY account */
local varn  bankwithd_d
local varn_hh  bankwithd_hh_d
preserve		
	egen x_tmp = total(`varn'), by(hh_faim_id round)
	replace x_tmp = 1 if x_tmp == 2
	gen dd =  x_tmp - `varn_hh'
	reg x_tmp `varn_hh'
	*tw scatter bank_dep_tmp exp_bank_dep_hh
	su x_tmp `varn_hh'
	su x_tmp `varn_hh' if e(sample)
restore


// Verify: Intensive Margins (in Ksh)
/* Deposit */
local varn  exp_bank_dep_usd
local varn_hh  exp_bank_dep_hh_usd
preserve		
	egen x_tmp = total(`varn'), by(hh_faim_id round)
	gen dd =  x_tmp - `varn_hh'
	reg x_tmp `varn_hh'
	*tw scatter bank_dep_tmp exp_bank_dep_hh
	su x_tmp `varn_hh'
	su x_tmp `varn_hh' if e(sample)
restore

/* Withdrawal */
local varn  bankwithd_usd
local varn_hh  bankwithd_hh_usd
preserve		
	egen x_tmp = total(`varn'), by(hh_faim_id round)
	gen dd =  x_tmp - `varn_hh'
	reg x_tmp `varn_hh'
	*tw scatter bank_dep_tmp exp_bank_dep_hh
	su x_tmp `varn_hh'
	su x_tmp `varn_hh' if e(sample)
restore

/* Deposit winsorized */
local varn  exp_bank_dep_w1_usd
local varn_hh  exp_bank_dep_hh_w1_usd
preserve		
	egen x_tmp = total(`varn'), by(hh_faim_id round)
	gen dd =  x_tmp - `varn_hh'
	reg x_tmp `varn_hh'
	*tw scatter bank_dep_tmp exp_bank_dep_hh
	su x_tmp `varn_hh'
	su x_tmp `varn_hh' if e(sample)
restore

/* Withdrawal winsorized */
local varn  bankwithd_w1_usd
local varn_hh  bankwithd_hh_w1_usd
preserve		
	egen x_tmp = total(`varn'), by(hh_faim_id round)
	gen dd =  x_tmp - `varn_hh'
	reg x_tmp `varn_hh'
	*tw scatter bank_dep_tmp exp_bank_dep_hh
	su x_tmp `varn_hh'
	su x_tmp `varn_hh' if e(sample)
restore



/* exp_total winsorized */
local varn  exp_total_w1_usd
local varn_hh  exp_total_hh_w1_usd
preserve		
	egen x_tmp = total(`varn'), by(hh_faim_id round)
	gen dd =  x_tmp - `varn_hh'
	reg x_tmp `varn_hh'
	*tw scatter bank_dep_tmp exp_bank_dep_hh
	su x_tmp `varn_hh'
	su x_tmp `varn_hh' if e(sample)
restore

/* exp_food winsorized */
local varn  exp_food_w1_usd
local varn_hh  exp_food_hh_w1_usd
preserve		
	egen x_tmp = total(`varn'), by(hh_faim_id round)
	gen dd =  x_tmp - `varn_hh'
	reg x_tmp `varn_hh'
	*tw scatter bank_dep_tmp exp_bank_dep_hh
	su x_tmp `varn_hh'
	su x_tmp `varn_hh' if e(sample)
restore

/* exp_personal winsorized */
local varn  exp_personal_w1_usd
local varn_hh  exp_personal_hh_w1_usd
preserve		
	egen x_tmp = total(`varn'), by(hh_faim_id round)
	gen dd =  x_tmp - `varn_hh'
	reg x_tmp `varn_hh'
	*tw scatter bank_dep_tmp exp_bank_dep_hh
	su x_tmp `varn_hh'
	su x_tmp `varn_hh' if e(sample)
restore

/* exp_hhgood winsorized */
local varn  exp_hhgood_w1_usd
local varn_hh  exp_hhgood_hh_w1_usd
preserve		
	egen x_tmp = total(`varn'), by(hh_faim_id round)
	gen dd =  x_tmp - `varn_hh'
	reg x_tmp `varn_hh'
	*tw scatter bank_dep_tmp exp_bank_dep_hh
	su x_tmp `varn_hh'
	su x_tmp `varn_hh' if e(sample)
restore

/* exp_total_children winsorized */
local varn  exp_total_children_w1_usd
local varn_hh  exp_total_children_hh_w1_usd
preserve		
	egen x_tmp = total(`varn'), by(hh_faim_id round)
	gen dd =  x_tmp - `varn_hh'
	reg x_tmp `varn_hh'
	*tw scatter bank_dep_tmp exp_bank_dep_hh
	su x_tmp `varn_hh'
	su x_tmp `varn_hh' if e(sample)
restore

/* Total income */
local varn  ksh_income_sum_usd
local varn_hh  ksh_income_sum_hh_usd
preserve		
	egen x_tmp = total(`varn'), by(hh_faim_id round)
	gen dd =  x_tmp - `varn_hh'
	reg x_tmp `varn_hh'
	*tw scatter bank_dep_tmp exp_bank_dep_hh
	su x_tmp `varn_hh'
	su x_tmp `varn_hh' if e(sample)
restore

/* Total income winsorized*/
local varn  ksh_income_sum_w1_usd
local varn_hh  ksh_income_sum_hh_w1_usd
preserve		
	egen x_tmp = total(`varn'), by(hh_faim_id round)
	gen dd =  x_tmp - `varn_hh'
	reg x_tmp `varn_hh'
	*tw scatter bank_dep_tmp exp_bank_dep_hh
	su x_tmp `varn_hh'
	su x_tmp `varn_hh' if e(sample)
restore




/* Covariates used in Table 4 */
egen b_housing_index=rmean(	b_walls_cement b_roof_iron b_floor_cement)

/* For housing index and animal */
egen h_index = max(b_housing_index), by(hh_faim_id)
egen log_ani = max(log_animal_durable), by(hh_faim_id)

local covar ///
		b_age ///
		b_education ///
		hh_size ///
		h_index ///
		log_ani ///
		earns_income_mktown_hh ///
		b_account_mobile_money_hh ///
		b_rosca ///
		ganga  ///
		sioport 
		
foreach var in `covar'{
	di "`var'"
	gen 	`var'_m = 1 if `var' ==.
	replace `var'_m = 0 if `var' !=.
	replace `var' = 0 	if `var' ==.
}

local covar_m ///
		b_age_m ///
		b_education_m ///
		hh_size_m ///
		h_index_m ///
		log_ani_m ///
		earns_income_mktown_hh_m ///
		b_account_mobile_money_hh_m ///
		b_rosca_m ///
		ganga_m ///
		sioport_m

tab round if female !=. & b_female_unmarried == 0

keep if b_female_unmarried == 0
gen female_tmp = mod(faim_id,10)-1
replace female = female_tmp if female == .
drop if female == .


/* Keep relevant variables */
local keep_vars ///
hasbank  ///
exp_bank_dep_d  ///
exp_bank_dep_usd   ///
exp_bank_dep_w1_usd   ///
bankwithd_d  ///
bankwithd_usd  ///
bankwithd_w1_usd  ///
exp_total_w1_usd  ///
exp_food_w1_usd  ///
exp_personal_w1_usd  ///
exp_hhgood_w1_usd  ///
exp_total_children_w1_usd  ///
ksh_income_sum_usd  ///
ksh_income_sum_w1_usd  ///
///
sqs ///
b_account_mobile_money ///
b_account_mobile_money_m ///
///
survey_year ///
survey_month ///
///
b_age ///
b_education ///
hh_size ///
b_rosca ///
///
b_age_m ///
b_education_m ///
hh_size_m ///
b_rosca_m ///
///
amtgavesp_usd amtgavesp_w1_usd amtgavesp_d






local keep_vars_hh ///
hasbank_hh ///
exp_bank_dep_d_hh ///
exp_bank_dep_hh_usd ///
exp_bank_dep_hh_w1_usd ///
bankwithd_hh_d ///
bankwithd_hh_usd ///
bankwithd_hh_w1_usd ///
exp_total_hh_w1_usd ///
exp_food_hh_w1_usd ///
exp_personal_hh_w1_usd ///
exp_hhgood_hh_w1_usd ///
exp_total_children_hh_w1_usd ///
ksh_income_sum_hh_usd ///
ksh_income_sum_hh_w1_usd ///
b_account_mobile_money_hh ///
b_account_mobile_money_hh_m ///
earns_income_mktown_hh ///
earns_income_mktown_hh_m ///
h_index ///
log_ani ///
h_index_m ///
log_ani_m ///
ganga ganga_m sioport sioport_m 


keep hh_faim_id faim_id round female  `keep_vars' `keep_vars_hh'

/* keep sampled households only */
merge m:1 hh_faim_id using data_ZD
drop if _merge != 3
drop _merge
drop id1 id2 Z1 Z2


replace female = 2-female
*keep hh_faim_id faim_id female round ganga sioport

reshape wide faim_id `keep_vars', i(hh_faim_id round) j(female)

order hh_faim_id round faim_id1 faim_id2 
ren faim_id1 id1
ren faim_id2 id2