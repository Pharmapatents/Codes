* Survival analysis: 

****************************
* Prepare the data: 
clear
use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Imitation_PC_PTA.dta", clear
* REpatentt: reissued patent, patent calculated based on the original patent:
* http://www.genericsweb.com/Calculating_US_expiry_dates.pdf
* Mistake in data? Patent application date: Feb 26, 1894/Dec 10, 1926
drop if patentt==522982 | patentt==1712251
* drop if _merge_OB_FDA==1, use only if keep obs with OB+drugs@FDA info
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

gen exclusivity_date_d=date(exclusivity_date, "MDY")
format exclusivity_date_d %d

replace Delay_A=0 if missing(Delay_A)
replace Delay_B=0 if missing(Delay_B)
replace Delay_C=0 if missing(Delay_C)
replace Delay_Non=0 if missing(Delay_Non)
replace Delay_Overlapping=0 if missing(Delay_Overlapping)
replace Applicant_delay=0 if missing(Applicant_delay)
replace Total_PTA=0 if missing(Total_PTA)

* expire: patent extension file
* sometimes patent expire_date_text includes patent extensions, sometimes not
* Patent extensiosn
gen expire_extend=expire_ext+days_given
replace expire_extend=patent_expire_date_d if missing(expire_extend)
format expire_extend %d
* length from the extension file
gen length=expire_extend-patent_application_date_d

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

gen term_start=patent_application_date_d
replace term_start=patent_grant_date_d if max_temp==temp2 & patent_application_date_d<date("Jun 8, 1995", "MDY")

format term_start %d

gen length_mo=(year(expire_extend)-year(patent_application_date_d))*12+month(expire_extend)-month(patent_application_date_d)
gen term_mo=(year(term_expiry)-year(patent_application_date_d))*12+month(term_expiry)-month(patent_application_date_d)

* Remove these four lines if want to compute patent duration from application:
replace term=term_expiry-patent_grant_date_d if max_temp==temp2 & patent_application_date_d<date("Jun 8, 1995", "MDY")
replace length=expire_extend-patent_grant_date_d if max_temp==temp2 & patent_application_date_d<date("Jun 8, 1995", "MDY")
replace length_mo=(year(expire_extend)-year(patent_grant_date_d))*12+month(expire_extend)-month(patent_grant_date_d) if max_temp==temp2 & patent_application_date_d<date("Jun 8, 1995", "MDY")
replace term_mo=(year(term_expiry)-year(patent_grant_date_d))*12+month(term_expiry)-month(patent_grant_date_d) if max_temp==temp2 & patent_application_date_d<date("Jun 8, 1995", "MDY")
***

* Months to PIV challenge during patent protection

gen censor_time=((year(term_expiry)-year(IV_approval_date_min))*12+month(term_expiry)-month(IV_approval_date_min))

gen IVtime=((year(IV_approval_date_min)-year(term_start))*12+month(IV_approval_date_min)-month(term_start))
* censored time (no PIV challenge during patent protection)
replace IVtime=term_mo if missing(IVtime) | censor_time<0 | IVtime<0

* event=1 indicates PIV challenge during patent protection and event=0 otherwise:

gen event=1
replace event=0 if IV_challenged_indicator==0 | censor_time<0 | IVtime<0

bysort patentt: gen first_o_p=1 if _n==1
replace first_o_p=0 if missing(first_o_p)

stset IVtime, failure(event)
sts graph if first_o_p==1

gen standard_term_17=0
replace standard_term_17=1 if max_temp==temp2 & patent_application_date_d<date("Jun 8, 1995", "MDY")

gen extension=0
replace extension=1 if Total_PTA+days_given>0
gen PTE=0
replace PTE=1 if days_given>0

* . sum claims_num
*
*    Variable |       Obs        Mean    Std. Dev.       Min        Max
* -------------+--------------------------------------------------------
*  claims_num |     34294    20.00044    20.42749          0        396

gen claims_more_ave=0
replace claims_more_ave=1 if claims_num>20.00044

sts graph if first_o_p==1, by(claims_more_ave) xlabel(minmax) ylabel(0.5[0.1]1)
sts graph if first_o_p==1 & year(term_start)<2000, by(standard_term_17)
sts graph if first_o_p==1 & year(term_start)>=1995, by(extension) xlabel(minmax) ylabel(0.5[0.1]1)


* Orphan Drug (ODE) - 7 years
* New Chemical (NCE)- 5 years
* "Other" Exclusivity - 3 years for a "change" if criteria are met
* Pediatric Exclusivity (PED) - 6 months added to existing Patents/Exclusivity
* Patent Challenge – (PC) – 180 days (this exclusivity is for ANDAs only)

gen Orphan=0 
replace Orphan=1 if exclusivity_code=="ODE"
gen NCE=0
replace NCE=1 if exclusivity_code=="NCE" | exclusivity_code=="NCE*" 
gen Pediatric=0
replace Pediatric=1 if exclusivity_code=="PED"

gen exclusivity_years=0
replace exclusivity_years=3 if exclusivity_date~="" 
replace exclusivity_years=5 if NCE==1
replace exclusivity_years=7 if Orphan==1
gen excl_expire=mdy(month(exclusivity_date_d),day(exclusivity_date_d), year(exclusivity_date_d)+exclusivity_years)
replace excl_expire=mdy(month(excl_expire)+6,day(excl_expire), year(excl_expire)) if exclusivity_code=="PED"
format excl_expire %d

* exclusivity during patent protection
gen exclusivity_valid=0
replace exclusivity_valid=1 if exclusivity_date_d>=term_start & excl_expire<=term_expiry
replace exclusivity_valid=1 if exclusivity_date_d>=term_start & exclusivity_date_d<=term_expiry
replace exclusivity_valid=1 if excl_expire>=term_start & excl_expire<=term_expiry
replace exclusivity_valid=1 if exclusivity_date_d<=term_start & excl_expire>=term_expiry

* exclusivity time during patent protection:
gen exclusivity_time=0
replace exclusivity_time=((year(excl_expire)-year(exclusivity_date_d))*12+month(excl_expire)-month(exclusivity_date_d)) if exclusivity_date_d>=term_start & excl_expire<=term_expiry
replace exclusivity_time=((year(term_expiry)-year(exclusivity_date_d))*12+month(term_expiry)-month(exclusivity_date_d)) if exclusivity_date_d>=term_start & exclusivity_date_d<=term_expiry & excl_expire>=term_expiry
replace exclusivity_time=((year(excl_expire)-year(term_start))*12+month(excl_expire)-month(term_start)) if excl_expire>=term_start & excl_expire<=term_expiry & exclusivity_date_d<=term_start
* 0 changes in the last case!
replace exclusivity_time=term_mo if exclusivity_date_d<=term_start & excl_expire>=term_expiry

hist exclusivity_time

gen excl_t_mt_40=0
replace excl_t_mt_40=1 if exclusivity_time>=40
sts graph if first_o_p==1, by(exclusivity_valid) xlabel(minmax) ylabel(0.5[0.1]1)
sts graph if first_o_p==1, by(excl_t_mt_40) xlabel(minmax) ylabel(0.5[0.1]1)

gen term_mo_sq=term_mo*term_mo
gen approval_year=year(approval_date_d)

gen claims_sq=claims_num*claims_num

* Controls: 

bysort patent_no: egen Orphan_p=max(Orphan)
bysort patent_no: egen NCE_p=max(NCE)
bysort patent_no: egen Pediatric_p=max(Pediatric)

gen tablet1=strpos(dfroute,"TABLET")
replace tablet1=1 if tablet1>0
bysort patent_no: egen tablet=max(tablet1)
drop tablet1
gen capsule1=strpos(dfroute,"CAPSULE")
replace capsule1=1 if capsule1>0
bysort patent_no: egen capsule=max(capsule1)
drop capsule1
gen injectable1=strpos(dfroute,"INJECTABLE")
replace injectable1=1 if injectable1>0
bysort patent_no: egen injectable=max(injectable1)
drop injectable1
* Nbr of patents per application:
bysort appl_no patentt: gen temp11=1 if _n==1
bysort appl_no: egen patents_per_appl=sum(temp11)
drop temp11
gen RE_t=substr(patent_no,1,2)
gen RE=0
replace RE=1 if RE_t=="RE"
drop RE_t
* _merge_OB_FDA==3 (matched): info in drugs@FDA
gen Priority_review1=0 if _merge_OB_FDA==3
replace Priority_review1=1 if Ther_Potential=="P" | Ther_Potential=="P*"
bysort appl_no: egen Priority_review=max(Priority_review1)
drop Priority_review1 
gen PTE_test=Reg__Rev__Test
replace PTE_test=subinstr(PTE_test, ".0","",.) 
replace PTE_test="" if PTE_test=="******"
replace PTE_test="" if PTE_test=="see RE 37,035"
destring PTE_test, replace
gen PTE_appl=Reg__Rev__App_l
replace PTE_appl=subinstr(PTE_appl, ".0","",.) 
replace PTE_appl="" if PTE_appl=="******"
destring PTE_appl, replace
bysort patent_no: egen exclusivity_time_p=max(exclusivity_time)
bysort patent_no: egen exclusivity_valid_p=max(exclusivity_valid)

stcox exclusivity_valid if first_o_p==1
stcurve, hazard


* Cox regressions:

stcox term_mo term_mo_sq claims_num claims_sq approval_year if first_o_p==1
stcox term_mo term_mo_sq claims_num claims_sq approval_year exclusivity_valid_p tablet capsule injectable Orphan_p Pediatric_p NCE_p patents_per_appl if first_o_p==1
stcurve, hazard xtitle("Time in months")
