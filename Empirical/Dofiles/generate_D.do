/* Variables computed from table 3 */
egen tot_num_transactions=rowtotal(total_dep_num total_wd_num),m
replace tot_num_transactions=0 if tot_num_transactions==. & account==1
gen account_active5t=(tot_num_transactions>=5) if tot_num_transactions!=.
gen account_active2t=(tot_num_transactions>=2) if tot_num_transactions!=.	
ren ever_used_account ever_used

// Note: the [missing] option of egen total return missing when all are missing
local vars open ever_used account_active5t account_active2t
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
inlist(hh_faim_id, 1003, 1070, 1053, 1034 , 1014, 1029 , 1022, 1059)
*/

su open_hh if account_any==1 & female==1 & round==1 & in_analysis_sample==1

/* For the dual headed sample 486 observation */
gen round1_plus = 0
replace round1_plus = round == 1
replace round1_plus = 1 if round == 3 & hh_faim_id == 4357

/* Part of Table 3 to verify */
noi di ""
noi di "Part of Table 3"
noi su open_hh ever_used_hh account_active5t_hh account_active2t_hh if b_female_unmarried==0 & female==1 & round==1 & in_analysis_sample==1
noi su open_hh ever_used_hh account_active5t_hh account_active2t_hh if b_female_unmarried==0 & female==1 & round1_plus==1 & in_analysis_sample==1


// bys round: tab open opened_joint if b_female_unmarried==0 & female==1 & account == 1
// sort hh_faim faim_id round female b_female_unmarried account open opened_joint
// ed hh_faim faim_id round female b_female_unmarried account spouse_account open opened_joint if hh_faim_id == 4276


/* Split, Reshape, Merge */
preserve
	collapse ///
	(mean) /// 
		m_hasbank = hasbank ///
		m_open=open ///
		m_open_joint = opened_joint ///
		m_ever_used = ever_used ///
		m_account_active5t = account_active5t ///
		m_account_active2t = account_active2t ///
	(sd) ///
		sd_hasbank = hasbank ///
		sd_open = open ///
		sd_open_joint = opened_joint ///
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
	save Data_D_tmp, replace
restore


use Data_Z,clear // indices generated from [generat_Z.do]

local varlist open open_joint ever_used account_active5t account_active2t
forv i = 1/2{
ren id`i' faim_id
merge 1:1 faim_id using Data_D_tmp
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
erase Data_D_tmp.dta

egen open_joint = rmax(open_joint1 open_joint2)
replace open1 = 1 if open_joint == 1
replace open2 = 1 if open_joint == 1

*ed hh_faim_id id1 id2 Z1 Z2 open1 open2 open_joint1 open_joint2 open_joint if hh_faim_id == 4276
