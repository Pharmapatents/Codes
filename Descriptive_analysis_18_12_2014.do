***************************************************
* DESCRIPTIVE ANALYSIS AND REGRESSIONS.           *
***************************************************

clear
use "C:\Users\tanja.saxell\Documents\Patent data\Merged\Imitation_PC_PTA.dta", clear
* REpatentt: reissued patent, patent calculated based on the original patent:
* http://www.genericsweb.com/Calculating_US_expiry_dates.pdf
* Outliers: Patent application date: Feb 26, 1894/Dec 10, 1926
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
gen exclusivity_date_d=date(exclusivity_date, "MDY")
format exclusivity_date_d %d

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

gen length_mo=(year(expire_extend)-year(patent_application_date_d))*12+month(expire_extend)-month(patent_application_date_d)
gen term_mo=(year(term_expiry)-year(patent_application_date_d))*12+month(term_expiry)-month(patent_application_date_d)

* Remove these four lines if want to compute patent duration from application:
replace term=term_expiry-patent_grant_date_d if max_temp==temp2 & patent_application_date_d<date("Jun 8, 1995", "MDY")
replace length=expire_extend-patent_grant_date_d if max_temp==temp2 & patent_application_date_d<date("Jun 8, 1995", "MDY")
replace length_mo=(year(expire_extend)-year(patent_grant_date_d))*12+month(expire_extend)-month(patent_grant_date_d) if max_temp==temp2 & patent_application_date_d<date("Jun 8, 1995", "MDY")
replace term_mo=(year(term_expiry)-year(patent_grant_date_d))*12+month(term_expiry)-month(patent_grant_date_d) if max_temp==temp2 & patent_application_date_d<date("Jun 8, 1995", "MDY")

* ADD PEDIATRIC EXCLUSIVITY, 
* FDA: "When pediatric exclusivity is granted to a drug product, 
* a period of 6 months exclusivity is added to all existing patents and exclusivity on all 
* applications held by the sponsor for that active moiety." 
* CHECK IS THIS A CORRECT WAY TO CALCULATE EXTENSION?
* IS IT ONLY FOR APPLICATIONS SINCE 1997?

gen PED_ex=0
replace PED_ex=1 if exclusivity_code=="PED"
bysort applicant ingredient_original: egen PED_appl_ingred=max(PED_ex)
* add 6 months:
* NOTE: NOW ONLY FOR TERM_MO! MORE DIFFICULT TO CALCULATE FOR TERM IN DAYS!!
replace term_mo=term_mo+6 if PED_appl_ingred==1

***



gen length_y=length_mo/12
gen term_y=term_mo/12


gen term_start=patent_application_date_d
replace term_start=patent_grant_date_d if max_temp==temp2 & patent_application_date_d<date("Jun 8, 1995", "MDY")

format term_start %d

* Term in years
corr term_y length_y
corr term_y length_y if length_y>=20
* 0.8832
bysort patentt: gen first_o_p=1 if _n==1
replace first_o_p=0 if missing(first_o_p)



****************************************
* IV:s
* Average number of claims per examiner, each patent is counted only once


gen examiner=ex_surname+" "+ex_name
* Average number of claims per examiner, each patent is counted only once

bysort patent_no examiner: gen first_o=1 if _n==1
replace first_o=0 if missing(first_o)
* a sum of claims per examiner
gen claims_temp=claims_num*first_o
bysort examiner: egen count_claims_per_examnr=sum(claims_temp)
* Excluding the claims of a patent
gen claims_count_excl=count_claims_per_examnr-claims_num
bysort examiner: egen sum_patents_per_examnr=sum(first_o)
gen ave_claims_excl=claims_count_excl/(sum_patents_per_examnr-1)
gen application_time=patent_grant_date_d-patent_application_date_d
gen at_temp=application_time*first_o
bysort examiner: egen count_at_per_examnr=sum(at_temp)
* Excluding the application time of a patent
gen at_ex_excl=count_at_per_examnr-application_time
gen ave_at_excl=at_ex_excl/(sum_patents_per_examnr-1)
gen ave_at_excl_zeros=ave_at_excl
replace ave_at_excl_zeros=0 if missing(ave_at_excl)
gen ave_claims_excl_zeros=ave_claims_excl
replace ave_claims_excl_zeros=0 if missing(ave_claims_excl)

hist sum_patents_per_examnr

********************************************************
gen pat_appl_year=substr(Patent_appl_date, -4, 4)
destring pat_appl_year, replace
gen term_expiry_year=year(term_expiry)

********************************
* Other characteristics:       *
********************************
* applicant has any new molecular entities/active ingredients within the group of an active ingredient
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

sum Challenged_active_ingredient IV_challenged_indicator Total_PTA Delay_A Delay_B Delay_C Applicant_delay days_given PTE_test PTE_appl claims_num length_y term_y pat_appl_year exclusivity_time_p exclusivity_valid_p Orphan_p NCE_p Pediatric_p tablet capsule injectable patents_per_appl RE Priority_review if first_o_p==1



sum pat_appl_year if IV_challenged_indicator==1
sum term_expiry_year if IV_challenged_indicator==1

gen Time_ind1=0
replace Time_ind1=1 if patent_application_date_d>=date("Jun 8, 1995", "MDY") & patent_application_date_d<date("May 29, 2000", "MDY")
gen Time_ind2=0
replace Time_ind2=1 if patent_application_date_d>=date("May 29, 2000", "MDY")
reg term_mo ave_at_excl Time_ind1 Time_ind2
reg term_mo ave_at_excl Time_ind1 Time_ind2 if first_o_p==1

* Original utility and plant patents issuing from applications filed on or after May 29, 2000 will be eligible for patent term adjustment if issuance of the patent is delayed due to one or more of the listed administrative delays.
reg claims_num ave_claims_excl if first_o_p==1
reg claims_num ave_claims_excl_zeros if first_o_p==1

* exclusivity_code=="PC", matched by ingredient strength dfroute 

gen PC_excl=0
replace PC_excl=1 if PC_applicant~=""

* Robustness: drop observations where patent info is missing

gen drop_ind=0
replace drop_ind=1 if Challenged_active_ingredient==1 & IV_challenged_indicator==0

bysort ingredient strength dfroute: gen f_o_PC=1 if _n==1
bysort ingredient: gen f_o_ingred=1 if _n==1
bysort ingredient: egen max_term=max(term)

gen max_term_sq=max_term*max_term

gen approval_year=year(approval_date_d)

gen claims_sq=claims_num*claims_num
gen term_sq=term*term
gen term_year=term*approval_year
gen term_sq_year=term_sq*approval_year
gen length_sq=length*length
gen approval_year_sq=approval_year*approval_year
gen term_mo_sq=term_mo*term_mo

twoway fpfitci IV_challenged_indicator claims_num if first_o_p==1 
twoway fpfitci IV_challenged_indicator length if first_o_p==1 
twoway fpfitci PC_excl claims_num if f_o_PC==1
twoway fpfitci PC_excl term if f_o_PC==1

* Correlations:
reg IV_challenged_indicator term_mo term_mo_sq claims_num claims_sq approval_year if first_o_p==1 
reg IV_challenged_indicator length length_sq claims_num claims_sq approval_year if first_o_p==1 
reg IV_challenged_indicator term term_sq claims_num approval_year exclusivity_valid_p if first_o_p==1 
reg IV_challenged_indicator term term_sq claims_num claims_sq approval_year exclusivity_valid_p tablet capsule injectable patents_per_appl Orphan_p Pediatric_p NCE_p if first_o_p==1
reg PC_excl term term_sq claims_num claims_sq approval_year if f_o_PC==1


gen appl_at=pat_appl_year*ave_at_excl
gen ave_at_excl_sq=ave_at_excl*ave_at_excl
gen appl_at_sq=pat_appl_year*ave_at_excl_sq

ivregress 2sls IV_challenged_indicator term term_sq approval_year exclusivity_time_p tablet capsule injectable patents_per_appl Orphan_p Pediatric_p NCE_p (claims_num=ave_claims_excl) if first_o_p==1, first 
ivreg2 IV_challenged_indicator claims_num claims_sq approval_year exclusivity_time_p tablet capsule injectable patents_per_appl Orphan_p Pediatric_p NCE_p (length length_sq=ave_at_excl ave_at_excl_sq appl_at appl_at_sq) if first_o_p==1, gmm2s first
ivreg2 IV_challenged_indicator claims_num claims_sq approval_year exclusivity_time_p tablet capsule injectable patents_per_appl Orphan_p Pediatric_p NCE_p (term term_sq=ave_at_excl ave_at_excl_sq appl_at appl_at_sq) if first_o_p==1, gmm2s first
ivreg2 IV_challenged_indicator claims_num claims_sq approval_year exclusivity_time_p (term term_sq=ave_at_excl ave_at_excl_sq appl_at appl_at_sq) if first_o_p==1 & drop_ind==0, gmm2s robust first

***
