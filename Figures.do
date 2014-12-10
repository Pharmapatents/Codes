**************************
* Codes for figures      *
**************************

clear
use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Imitation_PC_PTA.dta", clear
* REpatentt: reissued patent, patent calculated based on the original patent:
* http://www.genericsweb.com/Calculating_US_expiry_dates.pdf
* Mistake in data? Patent application date: Feb 26, 1894/Dec 10, 1926
drop if patentt==522982 | patentt==1712251
* Use only approved drugs in the OB
drop if _merge_OB_FDA==1
drop if missing(appl_no)

gen patent_application_date_d=date(Patent_appl_date, "MDY")
gen patent_expire_date_d=date(patent_expire_date_text, "MDY")
format patent_expire_date_d patent_application_date_d %d
replace days_given=0 if missing(days_given)
gen patent_grant_date_d=date(Patent_grant_date, "MDY")
format patent_grant_date_d %d
gen expire2=subinstr(expire, "00:00:00", "",.)
replace expire2=subinstr(expire2, " ", "",.)
gen expire_ext=date(expire2, "YMD")
drop expire2
format expire_ext %d
gen approval_date_d=date(approval_date, "MDY")
format approval_date_d %d
keep if ~missing(patent_application_date_d) & ~missing(patent_expire_date_d) & ~missing(approval_date_d)

* expire: patent extension file
* sometimes patent expire_date_text includes patent extensions, sometimes not
* Patent extensiosn
gen expire_extend=expire_ext+days_given
replace expire_extend=patent_expire_date_d if missing(expire_extend)
format expire_extend %d
* length from the extension file
gen length=expire_extend-patent_application_date_d
* Length in months because #days/year varies
gen length_mo=(year(expire_extend)-year(patent_application_date_d))*12+month(expire_extend)-month(patent_application_date_d)
gen length_y=length_mo/12

* Patent term (max length): standard length+PTA+PTE
* Compute patent term from application date
* Standard term: takes into account leap years!
gen temp1=mdy(month(patent_application_date_d),day(patent_application_date_d), year(patent_application_date_d)+20)
gen temp2=mdy(month(patent_grant_date_d),day(patent_grant_date_d), year(patent_grant_date_d)+17)
format temp1 temp2 %d
gen max_temp=max(temp1,temp2)
format max_temp %d
gen term_expiry=temp1
replace term_expiry=max_temp if patent_application_date_d<date("Jun 8, 1995", "MDY")
replace term_expiry=term_expiry+days_given+Total_PTA
format term_expiry %d
gen term=term_expiry-patent_application_date_d
gen term_mo=(year(term_expiry)-year(patent_application_date_d))*12+month(term_expiry)-month(patent_application_date_d)
gen term_y=term_mo/12
drop temp1 temp2 max_temp

bysort patentt: gen first_o_p=1 if _n==1
replace first_o_p=0 if missing(first_o_p)
sum term_y length_y
set scheme s2color

* Patent length vs. max length
twoway (histogram term_y if first_o_p==1, color(green)) ///
(histogram length_y if first_o_p==1, ///
fcolor(none) lcolor(black)), graphregion(color(white)) bgcolor(white) legend(order(1 "Maximum length" 2 "Length in Orange Book"))
graph export "C:\Users\tanja.saxell\Documents\GitHub\Codes\Results\Length_vs_term.pdf", replace

* Effective patent life (max)
gen effective_life=(year(term_expiry)-year(approval_date_d))*12+month(term_expiry)-month(approval_date_d)
gen effective_life_y=effective_life/12
hist effective_life_y if first_o_p==1, title("") xtitle("Maximum effective life (years)") graphregion(color(white)) bgcolor(white)
graph export "C:\Users\tanja.saxell\Documents\GitHub\Codes\Results\Effective_life.pdf", replace
gen effective_ext=(days_given+Total_PTA)/(term_expiry-approval_date_d)
sum effective_ext
hist effective_ext if first_o_p==1, title("") xtitle("Extensions/maximum effective life (years)") graphregion(color(white)) bgcolor(white)
hist effective_ext if first_o_p==1 & days_given+Total_PTA>0, title("") xtitle("Extensions/maximum effective life, PTA+PTE>0") graphregion(color(white)) bgcolor(white)
graph export "C:\Users\tanja.saxell\Documents\GitHub\Codes\Results\Extension_rel_effectivelife.pdf", replace

* Average application time by(grant_year)
gen p_appl_year=substr(Patent_appl_date, -4, 4)
destring p_appl_year, replace
replace p_appl_year=1990 if p_appl_year<=1990
label var p_appl_year "Patent application year"
gen Time=((year(patent_grant_date_d)-year(patent_application_date_d))*12+month(patent_grant_date_d)-month(patent_application_date_d))/12
label var Time "Patent application time, years"
set scheme s2color
twoway fpfitci Time p_appl_year if first_o_p==1, title("Patent application time (years)") xtitle("Patent application year") xlabel(minmax) graphregion(color(white)) bgcolor(white)
graph export "C:\Users\tanja.saxell\Documents\GitHub\Codes\Results\Applicationtime_year.pdf", replace
hist Time if first_o_p==1, title("") xtitle("Patent application time (years)") graphregion(color(white)) bgcolor(white)
graph export "C:\Users\tanja.saxell\Documents\GitHub\Codes\Results\Applicationtime.pdf", replace

twoway fpfitci term_y p_appl_year if first_o_p==1, title("Patent term (years)") xtitle("Patent application year") xlabel(minmax) graphregion(color(white)) bgcolor(white)
graph export "C:\Users\tanja.saxell\Documents\GitHub\Codes\Results\Patent_term_year.pdf", replace

gen PTA_PTE=days_given+Total_PTA
hist PTA_PTE if first_o_p==1 & PTA_PTE>0, title("") xtitle("Patent term extension+adjustment (days)") graphregion(color(white)) bgcolor(white)
graph export "C:\Users\tanja.saxell\Documents\GitHub\Codes\Results\PTA_PTE.pdf", replace

* max_expiration_d: term+patent_application_date
gen comp_time=((year(term_expiry)-year(Chall_approval_date_min))*12+month(term_expiry)-month(Chall_approval_date_min))/12
hist comp_time if first_o_p==1, title("") xtitle("Patent term expiry-first PIV challenge (years)") graphregion(color(white)) bgcolor(white)
graph export "C:\Users\tanja.saxell\Documents\GitHub\Codes\Results\Expiry_challange.pdf", replace
