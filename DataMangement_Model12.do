search plotplain

ssc install asdoc
ssc install outreg2
cap log close 
clear all
cap(set matsize 10000)
cap(set maxvar 10000)
set more off
set scheme plotplain


/* Command directory */
global pathcd = "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Data\LISS"
cd "$pathcd" //This specifies the directory

/* storage Data */
global pathdata = "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Data\LISS\Data"

/* storage Results and cleaned data */
global pathresults = "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Data\LISS\ResultsCleaned"

log using "LISS_DataManagement_2022.log", replace 

//-------------------------------------------------------------------------------------------
/* DATA MANGEMENT */
//-------------------------------------------------------------------------------------------
/* 1. Background Data set 2015-2021 */
foreach year of numlist 2015(1)2021 {
    use "$pathdata\Background\avars_`year'01_EN_1.0p.dta", clear
foreach month of numlist 1 2 3 4 5 6 7 8 9 {
append using "$pathdata\Background\avars_`year'0`month'_EN_1.0p.dta"
}
foreach month of numlist 10 11 12 {
append using "$pathdata\Background\avars_`year'`month'_EN_1.0p.dta"
}
sort nomem_encr wave
by nomem_encr wave: keep if _n==1 
compress
save "$pathdata\Background\LISS_Background`year'", replace
}

sort nomem_encr wave
tab wave

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

tab month year if leeftijd>=15 & leeftijd<=25
xtset nomem_encr datesurvey
tab wave
xtdescribe
//

keep nomem_encr year wave oplzon oplmet oplcat STRwave geslacht gebjaar leeftijd belbezig month datesurvey

save "$pathresults\LISS_Final_Cleaned_Model12.dta", replace 

//-------------------------------------------------------------------------------------------
use "$pathresults\LISS_Final_Cleaned_Model12.dta", clear
//-------------------------------------------------------------------------------------------

sum nomem_encr 
xtdescribe
//884475 cases, 18139 individuals, 

misstable tree geslacht leeftijd belbezig if leeftijd>=15 & leeftijd<=25

misstable summarize


//-------------------------------------------------------------------------------------------
//VARIABLE CONSTRUCTION
//-------------------------------------------------------------------------------------------

//Generates dummy var to indicate whether a person is studying/employed/self-employed/etc.
tab belbezig wave if year==2017
/* 71% attends school. 21.77% does paid employment */

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
replace agegroup=1 if (leeftijd>= 15 & leeftijd<= 17)
replace agegroup=2 if (leeftijd>= 18 & leeftijd<= 19)
replace agegroup=3 if (leeftijd==20)
replace agegroup=4 if (leeftijd==21)
replace agegroup=5 if (leeftijd==22)
replace agegroup=6 if (leeftijd>=23 & leeftijd<=25)

//Computing a new ID for individuals in treatment (18-22) and controlgroups (15-17 & 23-25)
gen temp=.
replace temp=1 if leeftijd>=15 & leeftijd<=17
replace temp=2 if leeftijd>=18 & leeftijd<=22
replace temp=3 if leeftijd>=23 & leeftijd<=25

egen newid=group(nomem_encr temp) 

//announcement  effect: dummy for the months between annoucement and start of the increase
gen announcement  = 0
replace announcement  = 1 if (datesurvey>= tm(2017m1) & datesurvey<= tm(2017m6))
tab announcement  datesurvey if year==2017

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

save "$pathresults\LISS_Final_Cleaned_Model12.dta", replace 