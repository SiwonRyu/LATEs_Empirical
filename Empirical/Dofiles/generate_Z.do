/* Treatment Assignments (Z)
자세한 계산은 Table A1을 참고

female == 1, round == 1, b_female_unmarried==0 인 obs에서 
Z1 = account (여성의 assignment)
Z2 = spouse_account (남성의 assignment)

bys round: tab account_both account
둘 다 TR인 경우 1790
둘 다 CG인 경우 3370
*/

/* Generate Treatment Assignments: Z1 for female, Z2 for male */


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
gen Z1o = account_any if b_female_unmarried==1 & round==1 & female==1
replace Z1o = account if b_female_unmarried==0 & round==1 & female==1
gen Z2o = spouse_account if b_female_unmarried==0 & round==1 & female==1

// Generate Household-Level Data: HHID, ID1, ID2, Z1, Z2
preserve
	keep if female == 1 & b_female_unmarried == 0 & round == 1
	keep hh_faim_id faim_id account spouse_account Z1o Z2o
	ren account Z1
	ren spouse_account Z2
	ren faim_id id1
	save Ztmp1, replace
restore

preserve
	keep if female == 0 & b_female_unmarried == 0 & round == 1
	keep hh_faim_id faim_id account spouse_account
	ren account Z2r
	ren spouse_account Z1r
	ren faim_id id2
	save Ztmp2, replace
restore

use Ztmp1, clear
merge 1:1 hh_faim_id using Ztmp2
replace id2 = hh_faim_id*10+1 if id2 == . 
// For husbands' id who didn't respond at round 1 (optional)

su Z1 Z1r Z1o Z2 Z2r Z2o  if _merge == 3
// Check coding error for account, spouse_account

// Replication of Table A1
tab Z1 Z2
drop _merge
cap erase Ztmp1.dta
cap erase Ztmp2.dta

keep hh_faim_id id1 id2 Z1 Z2
order hh_faim_id id1 id2 Z1 Z2

save Data_Z.dta,replace