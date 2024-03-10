set more off
clear all
macro drop _all

set mem 	300m
set maxvar 	30000

global baseroot "C:\rsw\Replication Datasets\Codes_for_3YP\Empirical"
cd "$baseroot"


/* Generate Treatment Assignments: Z1 for female, Z2 for male  */
use "data_tmp.dta", clear

*do "Analysis\generate_Z.do"
preserve
	keep if in_analysis_sample==1

	// hh_faim_id=4357 is observed in round 3,5,6 only: use info in observed round
	local N_obs_new1 = c(N)+1
	local N_obs_new2 = c(N)+2
	set obs `N_obs_new2'

	replace hh_faim = 4357 in `N_obs_new1'
	replace hh_faim = 4357 in `N_obs_new2'
	replace female = 0 in `N_obs_new1'
	replace female = 1 in `N_obs_new2'
	replace round = 1 in `N_obs_new1'
	replace round = 1 in `N_obs_new2'
	replace account = 0 in `N_obs_new1'
	replace account = 1 in `N_obs_new2'
	replace spouse_account = 1 in `N_obs_new1'
	replace spouse_account = 0 in `N_obs_new2'
	replace faim_id = 43571 in `N_obs_new1'
	replace faim_id = 43572 in `N_obs_new2'
	replace b_female_unmarried = 0 in `N_obs_new1'
	replace b_female_unmarried = 0 in `N_obs_new2'

	// Treatment Assignments
	gen Z1 = account_any if b_female_unmarried==1 & round==1 & female==1
	replace Z1 = account if b_female_unmarried==0 & round==1 & female==1
	gen Z2 = spouse_account if b_female_unmarried==0 & round==1 & female==1

	noi tab open opened_joint if Z1 == 1
	keep if round == 1 & b_female_unmarried == 0 & female == 1
	keep hh_faim Z1 Z2
	gen id1 = hh_faim_id*10+2
	gen id2 = hh_faim_id*10+1 
	order hh_faim id1 id2 Z1 Z2
	save data_Z.dta,replace
restore

do "Dofiles\generate_D.do"
save data_ZD, replace

do "Dofiles\generate_vars.do"
save data_vars,replace

use Data_vars, clear
merge m:1 hh_faim_id id1 id2 using Data_ZD
drop _merge
save data, replace


