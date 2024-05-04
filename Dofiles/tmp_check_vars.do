cd "C:\rsw\Replication Datasets\Kenya Savings"
use data, clear

/* Check: generated individual variables are same to those used in Table 9
foreach var in ///
exp_bank_dep_d ///
exp_bank_dep_w1_usd ///
bankwithd_d ///
bankwithd_w1_usd ///
amtgavesp_d ///
amtgavesp_w1_usd ///
exp_total_w1_usd ///
exp_personal_w1_usd ///
exp_food_w1_usd ///
exp_hhgood_w1_usd ///
ksh_income_sum_w1_usd ///
hasbank {
	display ""
	display "`var'"
	display ""
	qui{
	preserve
	use data,clear
	keep hh_faim_id round id1 id2 `var'1 `var'2
	su `var'1 `var'2
	save data_tmp_match,replace
	restore
	
	preserve
	use data_tmp_ind,clear
	keep if b_female_unmarried == 0
	keep hh_faim_id round female `var'_female `var'_male 
	drop if female == .
	reshape wide `var'_female `var'_male , i(hh_faim_id round) j(female)
	noi reg `var'_female0 `var'_female1 
	noi reg `var'_male0 `var'_male1 
	keep if e(sample)
	
	save data_tmp_ind_match,replace
	restore
	
	use data_tmp_match,clear
	merge 1:1 round hh_faim_id using data_tmp_ind_match
	
	noi su `var'1 `var'_female0 `var'_female1 if _merge == 3
	noi su `var'2 `var'_male0 `var'_male1  if _merge == 3
	erase data_tmp_match.dta
	erase data_tmp_ind_match.dta
	}
}
*/