/*******************************************************************************
	From the original replication pacakge for sample 
*******************************************************************************/
use faim_data.dta, clear

* Keep dual-headed households
keep if b_female_unmarried == 0

* Keep if both spouses surveyed in a given round
egen missing = total(resp_not_interviewed), by(hh_faim round)
keep if missing == 0
drop missing

* Conditions for analysis/attrition samples
gen sample = hasbank_hh !=. & survey_month !=. & round>=3 & round<=6 & female==1
egen in_analysis_sample  = max(sample), by(hh_faim)
drop sample


/*******************************************************************************
	Generate Treatment Assignments: Z1 for female, Z2 for male
*******************************************************************************/
preserve
	keep if in_analysis_sample==1
	keep if round == 1 & female == 1
	
	// Treatment Assignments
	gen Z1 = account
	gen Z2 = spouse_account
	noi tab open opened_joint if Z1 == 1
	
	keep hh_faim Z1 Z2
	gen id1 = hh_faim_id*10+2
	gen id2 = hh_faim_id*10+1 
	order hh_faim id1 id2 Z1 Z2
	
	save data_Z.dta,replace
restore


/*******************************************************************************
	Generate Take-up Vars 
*******************************************************************************/
// Note: the [missing] option of egen total return missing when all are missing
local vars open opened_joint
foreach var in `vars'{
	egen `var'_hh = total(`var'), by(hh_faim round) missing
	replace `var'_hh = 1 if `var'_hh == 2
}
*su open_hh if account_any==1 & female==1 & round==1 & in_analysis_sample==1

gen  zeros = 0
egen open_rev = rowmax(open opened_joint_hh zeros)

gen  hasbank3_tmp = hasbank if round == 3
egen hasbank3 = max(hasbank3_tmp), by(faim_id)
su   hasbank3 open_rev
bys  round: tab hasbank3 open

* Collect treatment take-up variables
preserve
	collapse ///
	(mean) m_hasbank = hasbank3 ///
		   m_open=open_rev ///
		   m_open_joint = opened_joint_hh ///
	(sd)   sd_hasbank = hasbank3 ///
		   sd_open = open_rev ///
		   sd_open_joint = opened_joint_hh ///
	, by(faim_id)
	su // check if sds are all zero
	tab m_open
	drop sd_*
	save data_D_tmp, replace
restore

* Merge
preserve
use data_Z,clear // indices generated from [generat_Z.do]

local varlist hasbank open open_joint

forv i = 1/2{
	ren id`i' faim_id
	merge 1:1 faim_id using data_D_tmp
		drop if _merge != 3
		drop _merge
		foreach var in `varlist'{
			ren m_`var' `var'`i'
		}
	ren faim_id id`i'
}

save  data_ZD, replace
erase data_Z.dta
erase data_D_tmp.dta
restore



/*******************************************************************************
	Generate Other Variables
*******************************************************************************/
/* Exchange rate: 80 Ksh/USD */
gen usd_income_sale_animal_hh_w1=ksh_income_sale_animal_hh/80
gen usd_income_sum_hh=ksh_income_sum_hh/80
gen b_animal_durable_usd=b_animal_durable/80

sum b_animal_durable_usd if round==1, d
gen b_animal_durable_usd_w1=b_animal_durable_usd
replace b_animal_durable_usd_w1=r(p99) if b_animal_durable_usd>r(p99) & b_animal_durable_usd!=.
replace exp_bank_dep_hh_d=0 	if hasbank_hh==0 & exp_bank_dep_hh_d==.
replace exp_bank_dep_hh_w1=0 	if hasbank_hh==0 & exp_bank_dep_hh_w1==.

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
foreach var in exp_bank_dep bankwithd amtgavesp {
		cap drop `var'_d
		gen `var'_d = 1 if `var' > 0
		replace `var'_d = 0 if `var' == 0 | `var' == .
		tabstat `var' , by(`var'_d)
		su `var' `var'_d
}
ren exp_bank_dep_hh_d exp_bank_dep_d_hh

/* Covariates used in Table 4: housing index and animal */
egen b_housing_index=rmean(	b_walls_cement b_roof_iron b_floor_cement )
egen h_index = max(b_housing_index), by(hh_faim_id)
egen log_ani = max(log_animal_durable), by(hh_faim_id)

replace female = mod(faim_id,10)-1 if female == .
drop if female == .

/* Keep relevant variables */
local 	keep_vars ///
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
		///
		survey_year ///
		survey_month ///
		///
		b_age ///
		b_education ///
		hh_size ///
		b_rosca ///
		///
		amtgavesp_usd amtgavesp_w1_usd amtgavesp_d ///
		transfHH_received_remit_d transfHH_sent_shar_d

local 	keep_vars_hh ///
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
		earns_income_mktown_hh ///
		h_index ///
		log_ani ///
		ganga sioport

keep hh_faim_id faim_id round female  `keep_vars' `keep_vars_hh'

/* keep sampled households only */
merge m:1 hh_faim_id using data_ZD
drop if _merge != 3
drop _merge
drop id1 id2 Z1 Z2

replace female = 2-female
reshape wide faim_id `keep_vars', i(hh_faim_id round) j(female)

order hh_faim_id round faim_id1 faim_id2 
ren faim_id1 id1
ren faim_id2 id2



/*******************************************************************************
	Merge
*******************************************************************************/
merge m:1 hh_faim_id id1 id2 using Data_ZD
drop _merge
save data, replace
erase data_ZD.dta