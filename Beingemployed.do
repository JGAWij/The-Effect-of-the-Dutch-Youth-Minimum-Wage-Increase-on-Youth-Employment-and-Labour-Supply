search plotplain

ssc install asdoc
ssc install outreg2
cap log close 
clear all
set scheme plotplain
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

//run "$path2\DataMangement_Model12.do"

use "$pathresults\LISS_Final_Cleaned_Model12", clear 


//-------------------------------------------------------------------------------------------
//CASE SELECTION - MODEL 2
//-------------------------------------------------------------------------------------------
sum nomem_encr 
//884475 cases

//STEP 1: SELECTING THE YOUTH 15-25
//Var indicating whether respondent is between the 15 and 25 years old.

gen select=1 if leeftijd >=15 & leeftijd <=25
drop if select==.
//dropped the cases about people older than 25 or younger than 15
sum nomem_encr 
//124,865 cases left

//STEP 2: SELECTING CASES WITHOUT MISSINGS & REMOVING OUTLIERS MODEL 1 PARTICIPATION

//Making a list of the variables which will be used in the analysis
global list1 year geslacht belbezig oplmet
misstable tree $list1

//dep var: being employed
tab employed
sum employed
tab employed leeftijd
bysort leeftijd: sum employed

//Checking cases and individuals based on newID
bysort newid: gen newid_count = _N
tab newid_count
histogram newid_count, frequency

// Check how much participants particiated through the years
bysort leeftijd: tab year if newid_count==1 

//T-test
gen ttestvar=0
replace ttestvar=1 if newid_count==1
label variable ttestvar "Person only occurs once in newid"

ttest leeftijd, by(ttestvar)
//significant differences between the group in terms of age (the age is lower in the group where newid_count==1)

ttest geslachtnew, by(ttestvar)
//significant differences between the groups in terms of gender (the amount of females is lower in the newid_count==1)

tab leeftijd ttestvar

/*
drop if newid_count==1
sum nomem_encr
//1002 cases deleted, 1555 cases left
*/



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
//significant difference (more women compared to population apart fro 2015)

sort nomem_encr
xtdescribe
sum nomem_encr
xtsum belbezig


//-------------------------------------------------------------------------------------------
//DESCRIPTIVES
//-------------------------------------------------------------------------------------------

global list2 year leeftijd unemployment CPI

//sysuse auto
asdoc sum $list2,  dec(2)

asdoc bysort year: tab leeftijd

gen timedummy17 = 1 if (year <= 2016) | (year== 2017 & month < 7)
tab datesurvey timedummy17

gen timedummy20 = 1 if (year > 2020) | (year== 2020 & month >= 7)
tab datesurvey timedummy20

gen timedummybetween = 1 if missing(timedummy17) & missing(timedummy20)
tab datesurvey timedummybetween


bysort temp timedummy17: sum employed
bysort temp timedummybetween: sum employed
bysort temp timedummy20: sum employed



//-------------------------------------------------------------------------------------------
//GRAPHS
//-------------------------------------------------------------------------------------------

tab agegroup employed


//Graph of labour force participation per agegroup (3 groups)
bysort temp datesurvey: egen employedmean1 = mean(employed)
gen employedmean2 = employedmean1*100
tab employedmean2 agegroup
twoway (line employedmean2 datesurvey if temp==1, sort) (line employedmean2 datesurvey if temp==2, sort) (line employedmean2 datesurvey if temp==3), tlabel(2015m1 "2015" 2016m1 "2016" 2017m1 "2017" 2018m1 "2018" 2019m1 "2019" 2020m1 "2020" 2021m1 "2021" 2022m1 "2022") ylabel(0(10)60) tline(2017m1, lpattern(shortdash)) tline(2017m7 2019m7, lwidth(0.5)) tline(2020m4, lpattern(dash_dot)) ytitle("%-being employed") xtitle("Time") legend(on) legend(label(1 "15-17 year olds") label(2 "18-22 year olds") label(3 "23-25 year olds")) 
graph export "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Do files\Beingemployed\Graph_participation3.png", as(png) name("Graph")



//-------------------------------------------------------------------------------------------
//ANALYSIS
//-------------------------------------------------------------------------------------------


pwcorr unemployment CPI timesinceevent temp, sig star(.05)
pwcorr temp timesinceevent, sig star(.05)

xtset newid datesurvey

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///2016 xtreg
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

putdocx begin
putdocx save employed_model2016a.docx, replace
shell ren 'employed_model2016a.docx' 'employed_model2016a.doc'

//base: 15-17 year olds, 2016
xtreg employed ib9.timesinceevent ib1.temp announcement covid, base fe vce(cluster  nomem_encr)
outreg2 using employed_model2016a.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17a)

//base: 15-17 year olds, 2016 + interaction
xtreg employed ib9.timesinceevent ib1.temp announcement covid ib9.timesinceevent#ib1.temp , base fe vce(cluster  nomem_encr)
outreg2 using employed_model2016a.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17b)

//base: 23-25 year olds, 2016
xtreg employed ib9.timesinceevent ib3.temp announcement covid, base fe vce(cluster  nomem_encr)
outreg2 using employed_model2016a.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25a)

//base: 23-25 year olds, 2016 + interaction
xtreg employed ib9.timesinceevent ib3.temp announcement covid ib9.timesinceevent#ib3.temp, base fe vce(cluster  nomem_encr)
outreg2 using employed_model2016a.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25b)

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//2017 xtreg
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

putdocx begin
putdocx save employed_model2017a.docx, replace
shell ren 'employed_model2017a.docx' 'employed_model2017a.doc'

//base: 15-17 year olds, 2017
xtreg employed ib10.timesinceevent ib1.temp announcement covid, base fe vce(cluster  nomem_encr)
outreg2 using employed_model2017a.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17a)

//base: 15-17 year olds, 2017 + interaction
xtreg employed ib10.timesinceevent ib1.temp announcement covid ib10.timesinceevent#ib1.temp, base fe vce(cluster  nomem_encr)
outreg2 using employed_model2017a.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17b)

//base: 23-25 year olds, 2017 
xtreg employed ib10.timesinceevent ib3.temp announcement covid, base fe vce(cluster  nomem_encr)
outreg2 using employed_model2017a.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25a)

//base: 23-25 year olds, 2017 + interaction
xtreg employed ib10.timesinceevent ib3.temp announcement covid ib10.timesinceevent#ib3.temp, base fe vce(cluster  nomem_encr)
outreg2 using employed_model2017a.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25b)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///2016 xtreg + announcement interaction
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

putdocx begin
putdocx save employed_model2016b.docx, replace
shell ren 'employed_model2016b.docx' 'employed_model2016b.doc'

//base: 15-17 year olds, 2016
xtreg employed ib9.timesinceevent ib1.temp announcement covid, base fe vce(cluster  nomem_encr)
outreg2 using employed_model2016b.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17a)

//base: 15-17 year olds, 2016 + interaction
xtreg employed ib9.timesinceevent ib1.temp announcement covid ib9.timesinceevent#ib1.temp b0.announcement##ib1.temp, base fe vce(cluster  nomem_encr)
outreg2 using employed_model2016b.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17b)

//base: 23-25 year olds, 2016
xtreg employed ib9.timesinceevent ib3.temp announcement covid, base fe vce(cluster  nomem_encr)
outreg2 using employed_model2016b.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25a)

//base: 23-25 year olds, 2016 + interaction
xtreg employed ib9.timesinceevent ib3.temp announcement covid  ib9.timesinceevent#ib3.temp b0.announcement##ib3.temp, base fe vce(cluster  nomem_encr)
outreg2 using employed_model2016b.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25b)



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//2017 xtreg + announcement interaction
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

putdocx begin
putdocx save employed_model2017b.docx, replace
shell ren 'employed_model2017b.docx' 'employed_model2017b.doc'

//base: 15-17 year olds, 2017
xtreg employed ib10.timesinceevent ib1.temp announcement covid, base fe vce(cluster  nomem_encr)
outreg2 using employed_model2017b.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17a)

//base: 15-17 year olds, 2017 + interaction
xtreg employed ib10.timesinceevent ib1.temp announcement covid ib10.timesinceevent#ib1.temp b0.announcement##ib1.temp, base fe vce(cluster  nomem_encr)
outreg2 using employed_model2017b.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17b)

//base: 23-25 year olds, 2017 
xtreg employed ib10.timesinceevent ib3.temp announcement covid, base fe vce(cluster  nomem_encr)
outreg2 using employed_model2017b.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25a)

//base: 23-25 year olds, 2017 + interaction
xtreg employed ib10.timesinceevent ib3.temp  announcement covid ib10.timesinceevent#ib3.temp b0.announcement##ib3.temp, base fe vce(cluster  nomem_encr)
outreg2 using employed_model2017b.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25b)

pause on
pause

log off
