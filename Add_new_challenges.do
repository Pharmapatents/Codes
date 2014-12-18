* Merge new challenges to the challenged_patents
clear
use "C:\Users\tanja.saxell\Documents\Patent data\Originals\challenged_patents.dta", clear
drop if missing(appl_no)
rename method method_1
rename Col22 method_2
rename Col23 method_3
drop Col5
save "C:\Users\tanja.saxell\Documents\Patent data\Merged\challenged_patents.dta", replace
clear
use "C:\Users\tanja.saxell\Documents\Patent data\Originals\Challenges_update_10_12_2014.dta", clear
drop v1* v2*
rename pii PIII_pat_1
gen PIII_pat_2=""
gen PIII_pat_3=""
gen PIII_pat_4=""
gen PIII_pat_5=""
rename doc_type DocType_x
rename patent1 Patent__1
rename patent2 Patent__2
rename patent3 Patent_3
rename patent4 Patent_4
rename patent5 Patent_5
rename patent6 Patent_6
rename patent7 Patent_7
rename patent8 Patent_8
rename patent9 Patent_9
rename method1 method_1
rename method2 method_2
rename method3 method_3

merge 1:1 appl_no using "C:\Users\tanja.saxell\Documents\Patent data\Merged\challenged_patents.dta"
drop _merge
save "C:\Users\tanja.saxell\Documents\Patent data\Merged\challenged_patents_update.dta", replace

use "C:\Users\tanja.saxell\Documents\Patent data\Originals\challenged_patent_update2.dta", clear
rename andanumber appl_no
rename challengedpatent1 Patent__1
rename challengedpatent2 Patent__2
rename challengedpatent3 Patent_3
rename challengedpatent4 Patent_4
rename challengedpatent5 Patent_5
rename challengedpatent6 Patent_6
rename v11 Patent_7
rename v12 Patent_8
rename v13 Patent_9
rename v14 Patent_10
rename v15 Patent_11
rename v16 Patent_12
tostring Patent__1, replace
tostring Patent__2, replace
tostring Patent_3, replace
tostring Patent_4, replace
tostring Patent_5, replace
tostring Patent_6, replace
tostring Patent_7, replace
tostring Patent_8, replace
tostring Patent_9, replace
tostring Patent_10, replace
tostring Patent_11, replace
tostring Patent_12, replace


save "C:\Users\tanja.saxell\Documents\Patent data\Originals\challenged_patent_update2_v2.dta", replace

* an indicator for missing patent numbers in challenged_patent_update2.dta

use "C:\Users\tanja.saxell\Documents\Patent data\Merged\challenged_patents_update.dta", clear
gen missing_patent_no=0
replace missing_patent_no=1 if Patent__1==""
keep appl_no missing_patent_no
merge 1:1 appl_no using "C:\Users\tanja.saxell\Documents\Patent data\Originals\challenged_patent_update2_v2.dta"
keep if ~missing(obyear)
* drop if patent no is not missing in the original data challenged_patents_update.dta
drop if missing_patent_no==0 
* 139 observations deleted
drop missing_patent_no _merge
merge 1:1 appl_no using "C:\Users\tanja.saxell\Documents\Patent data\Merged\challenged_patents_update.dta"

*     Result                           # of obs.
*    -----------------------------------------
*    not matched                         1,065
*        from master                        22  (_merge==1)
*        from using                      1,043  (_merge==2)
*
*    matched                                19  (_merge==3)
*    -----------------------------------------
* 19 observations where patent nbr is missing in using
* 22 observations where PIV challenge was only in the master file

drop obissuenumber obyear ingredienttradename tradenameoforiginaldrug
gen Exclusivity_section_patent_nbr=0
replace Exclusivity_section_patent_nbr=1 if _merge==1
label var Exclusivity_section_patent_nbr "Patent nbr source = Exclusivity section"
drop _merge
save "C:\Users\tanja.saxell\Documents\Patent data\Originals\challenged_patent_analysis.dta", replace

* Finally add other ob variables from challenged_patent_update2_v2.dta
use "C:\Users\tanja.saxell\Documents\Patent data\Originals\challenged_patent_update2_v2.dta", clear
keep appl_no obyear ingredienttradename tradenameoforiginaldrug
merge 1:1 appl_no using "C:\Users\tanja.saxell\Documents\Patent data\Originals\challenged_patent_analysis.dta"
drop _merge

* Patent nbr cleaning:
replace Patent__1=subinstr(Patent__1,",","",.)
replace Patent__2=subinstr(Patent__2,",","",.)
replace Patent_3=subinstr(Patent_3,",","",.)
replace Patent_4=subinstr(Patent_4,",","",.)
replace Patent_5=subinstr(Patent_5,",","",.)
replace Patent_6=subinstr(Patent_6,",","",.)
replace Patent_7=subinstr(Patent_7,",","",.)
replace Patent_8=subinstr(Patent_8,",","",.)
replace Patent_9=subinstr(Patent_9,",","",.)
replace Patent_10=subinstr(Patent_10,",","",.)
replace Patent_11=subinstr(Patent_11,",","",.)
replace Patent_12=subinstr(Patent_12,",","",.)
replace method_1=subinstr(method_1,",","",.)
replace method_2=subinstr(method_2,",","",.)
replace method_3=subinstr(method_3,",","",.)
replace PIII_pat_1=subinstr(PIII_pat_1,",","",.)
replace PIII_pat_2=subinstr(PIII_pat_2,",","",.)
replace PIII_pat_3=subinstr(PIII_pat_3,",","",.)

replace Patent__1=subinstr(Patent__1," ","",.)
replace Patent__2=subinstr(Patent__2," ","",.)
replace Patent_3=subinstr(Patent_3," ","",.)
replace Patent_4=subinstr(Patent_4," ","",.)
replace Patent_5=subinstr(Patent_5," ","",.)
replace Patent_6=subinstr(Patent_6," ","",.)
replace Patent_7=subinstr(Patent_7," ","",.)
replace Patent_8=subinstr(Patent_8," ","",.)
replace Patent_9=subinstr(Patent_9," ","",.)
replace Patent_10=subinstr(Patent_10," ","",.)
replace Patent_11=subinstr(Patent_11," ","",.)
replace Patent_12=subinstr(Patent_12," ","",.)
replace method_1=subinstr(method_1," ","",.)
replace method_2=subinstr(method_2," ","",.)
replace method_3=subinstr(method_3," ","",.)
replace PIII_pat_1=subinstr(PIII_pat_1," ","",.)
replace PIII_pat_2=subinstr(PIII_pat_2," ","",.)
replace PIII_pat_3=subinstr(PIII_pat_3," ","",.)

replace Patent__1=subinstr(Patent__1,".","",.)
replace Patent__2=subinstr(Patent__2,".","",.)
replace Patent_3=subinstr(Patent_3,".","",.)
replace Patent_4=subinstr(Patent_4,".","",.)
replace Patent_5=subinstr(Patent_5,".","",.)
replace Patent_6=subinstr(Patent_6,".","",.)
replace Patent_7=subinstr(Patent_7,".","",.)
replace Patent_8=subinstr(Patent_8,".","",.)
replace Patent_9=subinstr(Patent_9,".","",.)
replace Patent_10=subinstr(Patent_10,".","",.)
replace Patent_11=subinstr(Patent_11,".","",.)
replace Patent_12=subinstr(Patent_12,".","",.)
replace method_1=subinstr(method_1,".","",.)
replace method_2=subinstr(method_2,".","",.)
replace method_3=subinstr(method_3,".","",.)
replace PIII_pat_1=subinstr(PIII_pat_1,".","",.)
replace PIII_pat_2=subinstr(PIII_pat_2,".","",.)
replace PIII_pat_3=subinstr(PIII_pat_3,".","",.)

* 638 obs missing, 446 observations non-missing
save "C:\Users\tanja.saxell\Documents\Patent data\Originals\challenged_patent_analysis.dta", replace
