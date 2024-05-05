qui{
preserve
	keep hh_faim round id1 id2 Z1 Z2 D1 D2
	replace D1 = 0 if D1 == .
	replace D2 = 0 if D2 == .
	order hh_faim round id1 id2 Z1 Z2 D1 D2
	sort hh_faim round id1 id2
	export excel using "xlsx/data_ZD", firstrow(variables) replace
restore

preserve
	keep hh_faim round id1 id2 W_1*
	order hh_faim round id1 id2 
	sort hh_faim round id1 id2
	export excel using "xlsx/data_W1", firstrow(variables) replace
restore

preserve
	keep hh_faim round id1 id2 T_1*
	order hh_faim round id1 id2 
	sort hh_faim round id1 id2
	export excel using "xlsx/data_T1", firstrow(variables) replace
restore

preserve
	keep hh_faim round id1 id2 W_2*
	order hh_faim round id1 id2 
	sort hh_faim round id1 id2
	export excel using "xlsx/data_W2", firstrow(variables) replace
restore

preserve
	keep hh_faim round id1 id2 T_2*
	order hh_faim round id1 id2 
	sort hh_faim round id1 id2
	export excel using "xlsx/data_T2", firstrow(variables) replace
restore

preserve
	keep hh_faim round id1 id2 W_g* W_int*
	order hh_faim round id1 id2 
	sort hh_faim round id1 id2
	export excel using "xlsx/data_Wg", firstrow(variables) replace
restore

preserve
	keep hh_faim round id1 id2 T_g* T_int*
	order hh_faim round id1 id2 
	sort hh_faim round id1 id2
	export excel using "xlsx/data_Tg", firstrow(variables) replace
restore

preserve
	keep hh_faim round id1 id2 Y1 Y1_b
	order hh_faim round id1 id2 Y1 Y1_b
	sort hh_faim round id1 id2
	export excel using "xlsx/data_Y1", firstrow(variables) replace
restore

preserve
	keep hh_faim round id1 id2 Y2 Y2_b
	order hh_faim round id1 id2 Y2 Y2_b
	sort hh_faim round id1 id2
	export excel using "xlsx/data_Y2", firstrow(variables) replace
restore
}