set more off
clear all
macro drop _all

set mem 	300m
set maxvar 	30000

global baseroot "C:\rsw\Replication Datasets\Codes_for_3YP\Empirical"
cd "$baseroot"

use data_analysis, clear

/*******************************************************************************
	Estimate ITT effects, compare to Table 5-7
*******************************************************************************/
qui{
xtset round hh_faim_id
qui xtreg Y1 Z1 Y1_pre T_* W_*
est store ITT_ind1
qui xtreg Y1 Z1 Z2 Z_both Y1_pre T_* W_*
est store ITT_inf1
qui xtreg Y2 Z2 Y2_pre T_* W_*
est store ITT_ind2
qui xtreg Y2 Z1 Z2 Z_both Y2_pre T_* W_*
est store ITT_inf2
}
est table ITT_ind1 ITT_inf1 ITT_ind2 ITT_inf2, keep(Z1 Z2 Z_both) star b(%5.3f)


/*******************************************************************************
	Imbens Angrist (1994) LATE regression
*******************************************************************************/
ivregress 2sls Y1 (i.D1 = i.Z1) T_* W_*,r 
est store LATE1
local LATE1_coef = _b[1.D1]
local LATE1_se = _se[1.D1]
local LATE1_t = `LATE1_coef'/`LATE1_se'
local LATE1_p = 2*(1-normal(abs(`LATE1_t')))

ivregress 2sls Y2 (i.D2 = i.Z2 ) T_* W_*,r 
est store LATE2
local LATE2_coef = _b[1.D2]
local LATE2_se = _se[1.D2]
local LATE2_t = `LATE2_coef'/`LATE2_se'
local LATE2_p = 2*(1-normal(abs(`LATE2_t')))


/*******************************************************************************
	Vazquez (2022) IV regression 
for unit i, 
coef of Di is direct when i is complier
coef of Dj is the indirect when j is complier
*******************************************************************************/
ivregress 2sls Y1 (i.D1##i.D2 = i.Z1##i.Z2) T_* W_*,r 
est store VZ1
local VZ1_dir_coef = _b[1.D1]
local VZ1_dir_se = _se[1.D1]
local VZ1_dir_t = _b[1.D1]/_se[1.D1]
local VZ1_dir_p = 2*(1-normal(abs(`VZ1_dir_t')))

local VZ1_ind_coef = _b[1.D2]
local VZ1_ind_se = _se[1.D2]
local VZ1_ind_t = _b[1.D2]/_se[1.D2]
local VZ1_ind_p = 2*(1-normal(abs(`VZ1_ind_t')))

ivregress 2sls Y2 (i.D1##i.D2 = i.Z1##i.Z2)  T_* W_*,r 
est store VZ2
local VZ2_dir_coef = _b[1.D2]
local VZ2_dir_se = _se[1.D2]
local VZ2_dir_t = _b[1.D2]/_se[1.D2]
local VZ2_dir_p = 2*(1-normal(abs(`VZ2_dir_t')))

local VZ2_ind_coef = _b[1.D1]
local VZ2_ind_se = _se[1.D1]
local VZ2_ind_t = _b[1.D1]/_se[1.D1]
local VZ2_ind_p = 2*(1-normal(abs(`VZ2_ind_t')))



*ivregress 2sls Y_tilde1 D_tilde1,r nocon
*ivregress 2sls Y_tilde2 D_tilde2,r nocon







/* Stage 2: Estimate ITT  */
/* Ren regressions like Table 5, 7 */
/* Add the baseline outcome */




/* Stage 3: Estimate Compliance distribtuions */
gen iota = 1
gen Z11 = Z1*Z2
gen Z10 = Z1*(1-Z2)
gen Z01 = (1-Z1)*Z2
gen Z00 = (1-Z1)*(1-Z2)

for any Pz1 Pz2 P11 P10 P01 P00: cap drop X
for any 1 2: probit ZX W_* T_*, cluster(hh_faim) \ predict PzX
*for any 1 2: logit ZX W_* T_* Y1_pre Y2_pre, cluster(hh_faim) \ predict PzX
*for any 1 2: nl (ZX = normal({b0}+{xb:W_* T_* Y1_pre Y2_pre})) \ predict PzX


gen P11 = Pz1*Pz2
gen P10 = Pz1*(1-Pz2)
gen P01 = (1-Pz1)*Pz2
gen P00 = (1-Pz1)*(1-Pz2)

gen omega_11 = Z11/P11 /* z =(1,0) */
gen omega_01 = Z01/P01 /* z =(1,0) */
gen omega_10 = Z10/P10 /* z =(1,0) */
gen omega_00 = Z00/P00 /* z'=(0,0) */

gen omega_10_00 = omega_10 - omega_00
gen omega_01_00 = omega_01 - omega_00


for any omega Y_tilde1 Y_tilde2 D_tilde1 D_tilde2 D_tilde_both ///
P_Kh_lin1 P_Kh_lin2 P_Kh_lin12: cap drop X
gen omega 	 	 = omega_10_00
gen Y_tilde1 	 = Y1*omega
gen Y_tilde2 	 = Y2*omega
gen D_tilde1 	 = D1*omega
gen D_tilde2 	 = D2*omega
gen D_tilde_both = D1*D2*omega


/* Estimate PK */
for any D_tilde1 D_tilde2 D_tilde_both \ num 1/3 : reg X T_* \ predict P_Kh_linY
for any D_tilde1 D_tilde2 D_tilde_both \ num 1/3 : nl (X = normal({xb:T_*}+{b0})),  iterate(30000) \ predict P_Kh_nlY

su P_Kh*




/* Female, z=(1,0), z'=(0,0) */
ivregress 2sls Y_tilde1 (D_tilde1 D_tilde2 D_tilde_both=T_*), r nocon
est store Ti1
local Tdi1 = _b[D_tilde1]
local Tdi1_se = _se[D_tilde1]
local Tdi1_t = _b[D_tilde1]/_se[D_tilde1]
local Tdi1_p = 2*(1-normal(abs(`Tdi1_t')))

local Tii1 = _b[D_tilde2]
local Tii1_se = _se[D_tilde2]
local Tii1_t = _b[D_tilde2]/_se[D_tilde2]
local Tii1_p = 2*(1-normal(abs(`Tii1_t')))



/* Male, z=(1,0), z'=(0,0) */
ivregress 2sls Y_tilde2 (D_tilde2 D_tilde1 D_tilde_both= T_*), r nocon
est store Tj1
local Tdj1 = _b[D_tilde2]
local Tdj1_se = _se[D_tilde2]
local Tdj1_t = _b[D_tilde2]/_se[D_tilde2]
local Tdj1_p = 2*(1-normal(abs(`Tdj1_t')))

local Tij1 = _b[D_tilde1]
local Tij1_se = _se[D_tilde1]
local Tij1_t = _b[D_tilde1]/_se[D_tilde1]
local Tij1_p = 2*(1-normal(abs(`Tij1_t')))


tab Z_cat D_cat if omega_10 != 0 
tab Z_cat D_cat if omega_01 != 0 





for any omega Y_tilde1 Y_tilde2 D_tilde1 D_tilde2 D_tilde_both ///
P_Kh_lin1 P_Kh_lin2 P_Kh_lin12: cap drop X
gen omega 	 	 = omega_01_00
gen Y_tilde1 	 = Y1*omega
gen Y_tilde2 	 = Y2*omega
gen D_tilde1 	 = D1*omega
gen D_tilde2 	 = D2*omega
gen D_tilde_both = D1*D2*omega


/* Estimate PK */
reg D_tilde1 T_1* T_2* T_g* T_int*
predict P_Kh_lin1

reg D_tilde2 T_1* T_2* T_g* T_int*
predict P_Kh_lin2

reg D_tilde_both T_1* T_2* T_g* T_int*
predict P_Kh_lin12

su P_Kh*



/* Female, z=(0,1), z'=(0,0) */
ivregress 2sls Y_tilde1 (D_tilde1 D_tilde2 D_tilde_both= T_*), r nocon
est store Ti2
local Tdi2 = _b[D_tilde1]
local Tdi2_se = _se[D_tilde1]
local Tdi2_t = _b[D_tilde1]/_se[D_tilde1]
local Tdi2_p = 2*(1-normal(abs(`Tdi2_t')))

local Tii2 = _b[D_tilde2]
local Tii2_se = _se[D_tilde2]
local Tii2_t = _b[D_tilde2]/_se[D_tilde2]
local Tii2_p = 2*(1-normal(abs(`Tii2_t')))


/* Male, z=(0,1), z'=(0,0) */
ivregress 2sls Y_tilde2 (D_tilde2 D_tilde1 D_tilde_both= T_*), r nocon
est store Tj2
local Tdj2 = _b[D_tilde2]
local Tdj2_se = _se[D_tilde2]
local Tdj2_t = _b[D_tilde2]/_se[D_tilde2]
local Tdj2_p = 2*(1-normal(abs(`Tdj2_t')))

local Tij2 = _b[D_tilde1]
local Tij2_se = _se[D_tilde1]
local Tij2_t = _b[D_tilde1]/_se[D_tilde1]
local Tij2_p = 2*(1-normal(abs(`Tij2_t')))



foreach k in d i{
	foreach i in i j{
		foreach r in 1 2{
	di `T`k'`i'`r''
	}
	}
}

foreach k in d i{
	foreach i in i j{
		foreach r in 1 2{
			foreach s in _se _t _p{
	di "T`k'`i'`r'`s' =" `T`k'`i'`r'`s''
			}
	}
	}
}



est table LATE1 LATE2 VZ1 VZ2, b(%5.3f) keep(1.D1 1.D2) se(%5.3f)
est table LATE1 LATE2 VZ1 VZ2, b(%5.3f) keep(1.D1 1.D2) star
est table Ti1 Tj1 Ti2 Tj2, b(%5.3f) keep(D_tilde1 D_tilde2) star




preserve
qui{
clear
set obs 8
gen T = .
gen T_se = .
gen T_t = .
gen T_p = .

gen OSN = .
gen OSN_se = .
gen OSN_t = .
gen OSN_p = .

gen LATE = .
gen LATE_se = .
gen LATE_t = .
gen LATE_p = .

replace T = `Tdi1' in 1
replace T = `Tii1' in 2
replace T = `Tdj1' in 3
replace T = `Tij1' in 4
replace T = `Tdi2' in 5
replace T = `Tii2' in 6
replace T = `Tdj2' in 7
replace T = `Tij2' in 8

replace T_se = `Tdi1_se' in 1
replace T_se = `Tii1_se' in 2
replace T_se = `Tdj1_se' in 3
replace T_se = `Tij1_se' in 4
replace T_se = `Tdi2_se' in 5
replace T_se = `Tii2_se' in 6
replace T_se = `Tdj2_se' in 7
replace T_se = `Tij2_se' in 8

replace T_t = `Tdi1_t' in 1
replace T_t = `Tii1_t' in 2
replace T_t = `Tdj1_t' in 3
replace T_t = `Tij1_t' in 4
replace T_t = `Tdi2_t' in 5
replace T_t = `Tii2_t' in 6
replace T_t = `Tdj2_t' in 7
replace T_t = `Tij2_t' in 8

replace T_p = `Tdi1_p' in 1
replace T_p = `Tii1_p' in 2
replace T_p = `Tdj1_p' in 3
replace T_p = `Tij1_p' in 4
replace T_p = `Tdi2_p' in 5
replace T_p = `Tii2_p' in 6
replace T_p = `Tdj2_p' in 7
replace T_p = `Tij2_p' in 8



replace OSN = `VZ1_dir_coef' in 1
replace OSN = `VZ2_ind_coef' in 4
replace OSN = `VZ1_ind_coef' in 6
replace OSN = `VZ2_dir_coef' in 7

replace OSN_se = `VZ1_dir_se' in 1
replace OSN_se = `VZ2_ind_se' in 4
replace OSN_se = `VZ1_ind_se' in 6
replace OSN_se = `VZ2_dir_se' in 7

replace OSN_t = `VZ1_dir_t' in 1
replace OSN_t = `VZ2_ind_t' in 4
replace OSN_t = `VZ1_ind_t' in 6
replace OSN_t = `VZ2_dir_t' in 7

replace OSN_p = `VZ1_dir_p' in 1
replace OSN_p = `VZ2_ind_p' in 4
replace OSN_p = `VZ1_ind_p' in 6
replace OSN_p = `VZ2_dir_p' in 7


replace LATE = `LATE1_coef' in 1
replace LATE = `LATE2_coef' in 7

replace LATE_se = `LATE1_se' in 1
replace LATE_se = `LATE2_se' in 7

replace LATE_t = `LATE1_t' in 1
replace LATE_t = `LATE2_t' in 7

replace LATE_p = `LATE1_p' in 1
replace LATE_p = `LATE2_p' in 7
}
list, noobs table separator(10)
list T OSN LATE, noobs table separator(10)

restore