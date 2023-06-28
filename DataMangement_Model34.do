search plotplain

ssc install outreg2
ssc install asdoc
cap log close 
clear all
cap(set matsize 10000)
cap(set maxvar 10000)
set more off
set scheme plotplain


/* Command directory */
global pathcd = "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Data\LISS"
cd "${pathcd}" 

//This specifies the directory

/* storage Data */
global pathdata = "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Data\LISS\Data"

/* storage Results and cleaned data */
global pathresults = "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Data\LISS\ResultsCleaned"

log using "LISS_DataManagement_2022.log", replace 

//-------------------------------------------------------------------------------------------
/* DATA MANGEMENT */
//-------------------------------------------------------------------------------------------

/* 1. Background Data set 2015-2021 */
foreach year of numlist 2015 2016 2017 2018 2019 2020 2021 {
use "$pathdata\Background\avars_`year'04_EN_1.0p.dta", clear
foreach month of numlist 1 2 3 4 5 6 7 8 9 {
append using "$pathdata\Background\avars_`year'0`month'_EN_1.0p.dta"
}
foreach month of numlist 10 11 12 {
append using "$pathdata\Background\avars_`year'`month'_EN_1.0p.dta"
}
sort nomem_encr wave
by nomem_encr: keep if _n==1 
compress
save "$pathdata\Background\LISS_Background`year'", replace
}

/*Append all Background data sets: */
use "$pathdata\Background\LISS_Background2015", clear
foreach year of numlist 2016(1)2021 {
append using "$pathdata\Background\LISS_Background`year'"
des 
}
drop aantalhh aantalki positie lftdcat lftdhhh partner burgstat woonvorm woning sted brutoink brutoink_f nettoink netinc nettoink_f brutocat nettocat brutohh_f nettohh_f doetmee werving 

tostring wave, gen(STRwave) 
gen year = substr(STRwave, 1, 4)
tab year 
gen month = substr(STRwave, 5, 2)
tab month
destring year month, replace
gen datesurvey = ym(year, month)
format datesurvey %tm

sort nomem_encr year month
tab month
xtset nomem_encr year
xtdescribe
sum nomem_encr
// 80,170 cases of 18,139 individuals

save "$pathresults\LISS_Background_Cleaned.dta", replace

/* 2. Work and Schooling */

//2015-2018
local year=2015
local letters cw15h cw16i cw17j cw18k
foreach letter of local letters{
use "$pathdata\WorkSchooling\\`letter'_EN_2.0p.dta", clear  
renpfix `letter' a
gen year=`year'
compress
save "$pathdata\WorkSchooling\LISS_WorkSchooling`year'", replace
local year=`year'+1
}

//2019
use "$pathdata\WorkSchooling\cw19l_EN_3.0p.dta", clear 
renpfix cw19l a
gen year=2019
compress
save "$pathdata\WorkSchooling\LISS_WorkSchooling2019", replace

//2020-2021
local year=2020
local letters cw20m cw21n
foreach letter of local letters{
use "$pathdata\WorkSchooling\\`letter'_EN_1.0p.dta", clear  
renpfix `letter' a
gen year=`year'
compress
save "$pathdata\WorkSchooling\LISS_WorkSchooling`year'", replace
local year=`year'+1
}

/*Append all Work and Schooling data sets: */
use "$pathdata\WorkSchooling\LISS_WorkSchooling2015", clear
foreach year of numlist 2016(1)2021 {
append using "$pathdata\WorkSchooling\LISS_WorkSchooling`year'"
drop a501 a502 a503 a504  
}
//drop several variables
save "$pathresults\LISS_WorkSchooling_Cleaned.dta", replace

sort nomem_encr a_m
tab a_m
sort nomem_encr year
xtset nomem_encr year
xtdescribe
// 9.855 individuals, 40.161 cases

//-------------------------------------------------------------------------------------------
/* Merging */
//-------------------------------------------------------------------------------------------
use "$pathresults\LISS_Background_Cleaned.dta", clear
bysort nomem_encr year: gen n=_N 
//This counts how many times the individual-year combination exists in the data
tab n 
//All equal to one? This implies all individual-year combinations are unique
drop n
merge 1:1 nomem_encr year using "$pathresults\LISS_WorkSchooling_Cleaned.dta" 
//1:1, instead of m:1 or 1:m, as all individual-year combinations should be unique
drop if _merge==2 

drop _merge

//Setting the panel structure
order nomem_encr year
sort nomem_encr year
xtset nomem_encr year
xtdescribe
sum nomem_encr
// 18139 individuals, 80,170 cases

keep nomem_encr year wave oplzon oplmet oplcat STRwave geslacht gebjaar belbezig month datesurvey a145 a127 a003
save "$pathresults\LISS_Final_Cleaned2.dta", replace 
//Saving the final dataset


use "$pathresults\LISS_Final_Cleaned2.dta", clear
sum nomem_encr 
misstable summarize

//-------------------------------------------------------------------------------------------
//VARIABLE CONSTRUCTION
//-------------------------------------------------------------------------------------------

//Recoding gender
tab geslacht
gen geslachtnew = geslacht-1
label variable geslachtnew "Being female"

//ADDING UNEMPLOYMENT AS BUSINESSCYCLE-EFFECT
gen unemployment=7.91 if year==2015
replace unemployment=7.01 if year==2016
replace unemployment=5.89 if year==2017
replace unemployment=4.88 if year==2018
replace unemployment=4.43 if year==2019
replace unemployment=4.86 if year==2020
replace unemployment=4.24 if year==2021
//data is from 'Arbeidsdeelname en werkloosheid per maand' CBS: https://opendata.cbs.nl/statline/?dl=67DFE#/CBS/nl/dataset/80590ned/table

//ADDING AVERAGE INFACTION AS BUSINESSCYCLE-EFFECT
gen CPI=0.6 if year==2015
replace CPI=0.3 if year==2016
replace CPI=1.4 if year==2017
replace CPI=1.7 if year==2018
replace CPI=2.6 if year==2019
replace CPI=1.3 if year==2020
replace CPI=2.7 if year==2021
//data is from "Consumentenprijzen; prijsindex 2015=100" retrieved from https://opendata.cbs.nl/#/CBS/nl/dataset/83131NED/table

//Var indicating main occupation is being employed
gen employed=0
replace employed=1 if belbezig==1 | belbezig==2 | belbezig==3
label variable employed "Employed"
tab employed belbezig

//Var indicating main occupation
gen unemployed=0
replace unemployed=1 if belbezig==4 | belbezig==5
label variable employed "Unemployed"
tab unemployed belbezig

//Var indicating time since event with 10 as central value
gen timesinceevent=0
replace timesinceevent= (year-2017)+10
tab timesinceevent year

gen time2015=0
replace time2015=timesinceevent if year==2015
gen time2016=0
replace time2016=timesinceevent if year==2016
gen time2017=0
replace time2017=timesinceevent if year==2017
gen time2018=0
replace time2018=timesinceevent if year==2018
gen time2019=0
replace time2019=timesinceevent if year==2019
gen time2020=0
replace time2020=timesinceevent if year==2020
gen time2021=0
replace time2021=timesinceevent if year==2021

tab time2015 timesinceevent
tab time2016 timesinceevent
tab time2017 timesinceevent
tab time2018 timesinceevent
tab time2019 timesinceevent
tab time2020 timesinceevent
tab time2021 timesinceevent

//Var indicating age-group (wide)
gen agegroup=0
replace agegroup=1 if (a003>= 15 & a003<= 17)
replace agegroup=2 if (a003>= 18 & a003<= 19)
replace agegroup=3 if (a003==20)
replace agegroup=4 if (a003==21)
replace agegroup=5 if (a003==22)
replace agegroup=6 if (a003>=23 & a003<=25)

//Computing a new ID for individuals in treatment (18-22) and controlgroups (15-17 & 23-25)
gen temp=.
replace temp=1 if a003>=15 & a003<=17
replace temp=2 if a003>=18 & a003<=22
replace temp=3 if a003>=23 & a003<=25

egen newid=group(nomem_encr temp) 


//Effect of policy in total: dummy for the period before
gen policyeffect = 0
replace policyeffect = 1 if (datesurvey>= tm(2017m7))

//Effect of policy2017
gen policyeffect17 = 0
replace policyeffect17 = 1 if (datesurvey>= tm(2017m7) & datesurvey<= tm(2019m6))

//Effect of policy2019
gen policyeffect19 = 0
replace policyeffect19 = 1 if (datesurvey>= tm(2019m7))

//covid effect
gen covid = 0
replace covid = 1 if (datesurvey>= tm(2020m3))
tab covid year

tab policyeffect policyeffect17
tab policyeffect policyeffect19

save "$pathresults\LISS_Final_Cleaned2.dta", replace 
//Saving the final dataset