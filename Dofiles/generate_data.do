/*******************************************************************************
	From the original replication pacakge for sample 
*******************************************************************************/
* Keep if both spouses surveyed in a given round
egen missing = total(resp_not_interviewed), by(hh_faim round)
keep if missing == 0
drop missing

* Conditions for analysis/attrition samples
gen sample3 = hasbank_hh !=. & survey_month !=. & round>=3 & round<=6 & female==1
gen sample1 = hasbank_hh !=. & survey_month !=. & round>=1 & round<=6 & female==1
egen in_analysis_sample = max(sample3), by(hh_faim)
egen in_attrition_sample = max(sample1), by(hh_faim)
drop sample*


/*******************************************************************************
	Generate Treatment Assignments: Z1 for female, Z2 for male
*******************************************************************************/
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


/*******************************************************************************
	Generate Take-up Vars 
*******************************************************************************/
*do "Dofiles\generate_D.do"

* Variables computed from table 3
egen tot_num_transactions=rowtotal(total_dep_num total_wd_num), missing
replace tot_num_transactions=0 if tot_num_transactions==. & account==1
gen account_active5t=(tot_num_transactions>=5) if tot_num_transactions!=.
gen account_active2t=(tot_num_transactions>=2) if tot_num_transactions!=.	
ren ever_used_account ever_used


// Note: the [missing] option of egen total return missing when all are missing
local vars open opened_joint ever_used account_active5t account_active2t
foreach var in `vars'{
	egen `var'_hh = total(`var'), by(hh_faim round) missing
	replace `var'_hh = 1 if `var'_hh == 2
}
/* Check: For the take-up,
*1022 female=missing, male=missing
*1003 female=0, male=missing
*1070 female=1, male=missing
*1053 female=missing, male=0
*1034 female=missing, male=1
*1014 female=0, male=1
*1029 female=1, male=0
*1059 female=1, male=1
ed open_hh open_hh2 hh_faim_id round female open if ///
inlist(hh_faim_id, 1003, 1070, 1053, 1034 , 1014, 1029 , 1022, 1059) */

su open_hh if account_any==1 & female==1 & round==1 & in_analysis_sample==1

* For the dual headed sample 486 observation
gen round1_plus = 0
replace round1_plus = round == 1
replace round1_plus = 1 if round == 3 & hh_faim_id == 4357

* Part of Table 3 to verify
noi di ""
noi di "Part of Table 3: took-up/ever used/2tr/5tr"
noi su open_hh ever_used_hh account_active2t_hh account_active5t_hh  ///
	if female==1 & round==1 & in_analysis_sample==1

noi di ""
noi di "Part of Table 3: for dual-headed sample"
noi su open_hh ever_used_hh opened_joint account_active5t_hh account_active2t_hh ///
	if b_female_unmarried==0 & female==1 & round==1 & in_analysis_sample==1
noi su open_hh ever_used_hh opened_joint account_active5t_hh account_active2t_hh  ///
	if b_female_unmarried==0 & female==1 & round1_plus==1 & in_analysis_sample==1

gen zeros = 0
egen open_rev = rowmax(open opened_joint_hh zeros)


gen hasbank3_tmp = hasbank if round == 3
egen hasbank3 = max(hasbank3_tmp), by(faim_id)
su hasbank3 open_rev
bys round: tab hasbank3 open

* Split, Reshape, Merge
preserve
	collapse ///
	(mean) /// 
		m_hasbank = hasbank3 ///
		m_open=open_rev ///
		m_open_joint = opened_joint_hh ///
		m_ever_used = ever_used ///
		m_account_active5t = account_active5t ///
		m_account_active2t = account_active2t ///
	(sd) ///
		sd_hasbank = hasbank3 ///
		sd_open = open_rev ///
		sd_open_joint = opened_joint_hh ///
		sd_ever_used = ever_used ///
		sd_account_active5t = account_active5t ///
		sd_account_active2t = account_active2t ///
	, by(faim_id)
	su // check if sds are all zero
	tab m_open
	tab m_ever_used
	tab m_account_active5t
	tab m_account_active2t
	drop sd_*
	save data_D_tmp, replace
restore


preserve
use data_Z,clear // indices generated from [generat_Z.do]

local varlist hasbank open open_joint ever_used account_active5t account_active2t

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

foreach var in `varlist'{
	egen `var'_hh = rowtotal(`var'1 `var'2) 
	replace `var'_hh = 1 if `var'_hh == 2 
	
	egen `var'_hh2 = rowtotal(`var'1 `var'2),m 
	replace `var'_hh2 = 1 if `var'_hh2 == 2 	
}

noi di ""
noi di "Compare Generated Take-up Variables to Table 3"
noi su open_hh open_hh2 ever_used_hh ever_used_hh2 ///
account_active5t_hh account_active5t_hh2 ///
account_active2t_hh account_active2t_hh2 if hh_faim_id != 4357

noi su open_hh open_hh2 ever_used_hh ever_used_hh2 ///
account_active5t_hh account_active5t_hh2 ///
account_active2t_hh account_active2t_hh2

*ed hh_faim_id id1 id2 Z1 Z2 open1 open2 open_joint1 open_joint2 open_joint if hh_faim_id == 4276

save data_ZD, replace
erase data_Z.dta
erase data_D_tmp.dta
restore



/*******************************************************************************
	Generate Other Variables
*******************************************************************************/
do "Dofiles\generate_vars.do"
merge m:1 hh_faim_id id1 id2 using Data_ZD
drop _merge
save data, replace
erase data_ZD.dta

