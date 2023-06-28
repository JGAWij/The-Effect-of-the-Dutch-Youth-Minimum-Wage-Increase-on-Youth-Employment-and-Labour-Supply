search plotplain

ssc install asdoc
cap log close 
clear all
set more off
set scheme plotplain

/* Command directory */
global pathcd = "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Data\LISS"
cd "$pathcd" //This specifies the directory

/* storage Data */
global pathdata = "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Data\LISS\Data"

/* storage Results and cleaned data */
global pathresults = "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Data\LISS\ResultsCleaned"

/* data mangement */
global path2 = "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Dofiles\"

log using "LISS_DataManagement_2022.log", replace 

//run "$path2\DataMangement_Model34.do"

use "$pathresults\LISS_Final_Cleaned2.dta", clear
sum nomem_encr 
misstable summarize


//-------------------------------------------------------------------------------------------
//CASE SELECTION - MODEL 4
//-------------------------------------------------------------------------------------------
sum nomem_encr 
xtdescribe
//80,170 cases, 18139 individuals

//STEP 1: SELECTING THE YOUTH 15-25
//Var indicating whether respondent is between the 15 and 25 years old.

gen select=1 if a003 >=15 & a003 <=25
drop if select==.
//dropped the cases about people older than 25 or younger than 15
sum nomem_encr 
xtdescribe
//4,521 cases,  1739 individuals

//STEP 2: SELECTING CASES WITHOUT MISSINGS & REMOVING OUTLIERS
//Making a list of the variables which will be used in the analysis
global list1 a145 year geslacht
misstable tree $list1
//46% of the cases is missing
drop if a145==.
sum nomem_encr 
xtdescribe
//2,471 cases of  1215 individuals
//2422 cases of 1187 individuals
tab a145
histogram a145
//no cases higher than 80
drop if a145==0
//2,398 cases of 1187 individuals
sum nomem_encr 
xtdescribe

bysort year: sum a145
dotplot a145 if year==2017
dotplot a145 if year==2020

//generating the log of satisfaction with working hours
gen a145_log = ln(a145)
//by taking the log all people 

label variable a145_log "log of satisfaction working hours"

histogram a145_log
sktest a145_log

//-------------------------------------------------------------------------------------------
//MISSING VALUE ANALYSIS
//-------------------------------------------------------------------------------------------

/*T-TESTS 
- DATA FROM SAMPLE BEFORE DELETING CASES */

summarize geslachtnew

//Data computed based on Statistics Netherlands 'Bevolking op 1 januari en gemiddeld; geslacht, leeftijd en regio' by focussing on 15-25 year-olds retrieved from: https://www.cbs.nl/nl-nl/cijfers/detail/03759ned 
ttest geslachtnew == 0.504585898 if year==2015 
ttest geslachtnew == 0.504265533 if year==2016 
ttest geslachtnew == 0.503843426 if year==2017 
ttest geslachtnew == 0.503695983 if year==2018 
ttest geslachtnew == 0.503471527 if year==2019 
ttest geslachtnew == 0.503203288 if year==2020 
ttest geslachtnew == 0.502928199 if year==2021 
//significant difference (more women compared to population)


//Checking cases and individuals based on newID
bysort newid: gen newid_count = _N
tab newid_count
histogram newid_count, frequency

// Check how much participants particiated through the years
bysort a003: tab year if newid_count==1 

//T-test
gen ttestvar=0
replace ttestvar=1 if newid_count==1
label variable ttestvar "Person only occurs once in newid"

ttest a003, by(ttestvar)
//significant difference
ttest geslachtnew, by(ttestvar)
//significant difference
tab a003 ttestvar
//only one person of 15 is joining

//Checking cases and individuals based on newID
bysort nomem_encr: gen nomem_encr_count = _N
tab nomem_encr_count
histogram nomem_encr_count, frequency

twoway histogram newid_count, color(ltblue) xlabel(1(1)7) frequency|| histogram nomem_encr_count, lcolor(black) fcolor(none) frequency legend(label(1 "New ID") label(2 "Nomem_encr"))

// Check how much participants particiated through the years
bysort a003: tab year if nomem_encr_count==1 

//T-test
gen ttestvar=0
replace ttestvar=1 if nomem_encr_count==1
label variable ttestvar "Person only occurs once in newid"

ttest a003, by(ttestvar)
//significant difference
ttest geslachtnew, by(ttestvar)
//significant difference
tab a003 ttestvar
//only one person of 15 is joining


//-------------------------------------------------------------------------------------------
//GRAPHS
//-------------------------------------------------------------------------------------------

//Graph of average amount of hours worked per week (3 groups)
bysort temp year: egen satisfactionmean2 = mean(a145)
twoway (connected satisfactionmean2 year if temp==1, sort) (connected satisfactionmean2 year if temp==2, sort) (connected satisfactionmean2 year if temp==3), xlabel(2015(1)2021) xline(2018 2020) ylabel(0(5)35) ytitle("Willingness to work in hours") legend(on) legend(label(1 "15-17 year olds") label(2 "18-22 year olds") label(3 "23-25 year olds"))  
graph export "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Do files\Working hours\SatisfactionWorkingHours.png", as(png) name("Graph")

histogram year, frequency xlabel(2015(1)2021) ylabel(0(50)450)

twoway (histogram year if temp==1, frequency) (histogram year if temp==2, frequency) (histogram year if temp==3, frequency), legend(label(1 "Category 1") label(2 "Category 2"))

tab temp year

//-------------------------------------------------------------------------------------------
//DESCRIPTIVES
//-------------------------------------------------------------------------------------------

gen timedummy18 = 1 if year < 2018
gen timedummybetween = 1 if year < 2020 & year <= 2018
gen timedummy20 = 1 if year >= 2020


bysort temp timedummy18: sum a145
bysort temp timedummybetween: sum a145
bysort temp timedummy20: sum a145

gen timedummy18 = 1 if year < 2018
gen timedummybetween = 1 if year < 2020 & year <= 2018
gen timedummy20 = 1 if year >= 2020


bysort temp timedummy18: sum a145
bysort temp timedummybetween: sum a145
bysort temp timedummy20: sum a145



//-------------------------------------------------------------------------------------------
//ANALYSIS
//-------------------------------------------------------------------------------------------


xtset newid datesurvey

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///2016 xtreg
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//base: 15-17 year olds, 2016
putdocx begin
putdocx save satisfaction_model2016.docx, replace
shell ren 'satisfaction_model2016.docx' 'satisfaction_model2016.doc'

xtreg a145_log ib9.timesinceevent ib1.temp covid, base fe vce(cluster nomem_encr)
outreg2 using satisfaction_model2016.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17a)

//base: 15-17 year olds, 2016 + interaction
xtreg a145_log ib9.timesinceevent ib1.temp covid ib9.timesinceevent#ib1.temp, base fe vce(cluster nomem_encr)
outreg2 using satisfaction_model2016.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17b)

//base: 23-25 year olds, 2016 
xtreg a145_log ib9.timesinceevent ib3.temp covid, base fe vce(cluster nomem_encr)
outreg2 using satisfaction_model2016.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25a)

//base: 23-25 year olds, 2016 + interaction
xtreg a145_log ib9.timesinceevent ib3.temp covid ib9.timesinceevent#ib3.temp, base fe vce(cluster nomem_encr)
outreg2 using satisfaction_model2016.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25b)


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//2017 xtreg
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//base: 15-17 year olds, 2017
putdocx begin
putdocx save satisfaction_model20172017.docx, replace
shell ren 'satisfaction_model2017.docx' 'satisfaction_model2017.doc'

xtreg a145_log ib10.timesinceevent ib1.temp covid, base fe vce(cluster nomem_encr)
outreg2 using satisfaction_model2017.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17a)

//base: 15-17 year olds, 2017 + interaction
xtreg a145_log ib10.timesinceevent ib1.temp covid ib10.timesinceevent#ib1.temp, base fe vce(cluster nomem_encr)
outreg2 using satisfaction_model2017.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17b)

//base: 23-25 year olds, 2017 
xtreg a145_log ib10.timesinceevent ib3.temp covid, base fe vce(cluster nomem_encr)
outreg2 using satisfaction_model2017.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25a)

//base: 23-25 year olds, 2017 + interaction
xtreg a145_log ib10.timesinceevent ib3.temp covid ib10.timesinceevent#ib3.temp, base fe vce(cluster nomem_encr)
outreg2 using satisfaction_model2017.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25b)

log off
