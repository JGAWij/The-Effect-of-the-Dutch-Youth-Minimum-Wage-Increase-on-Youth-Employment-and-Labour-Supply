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

//run "$path2\DataMangement_Model12.do"

use "$pathresults\LISS_Final_Cleaned_Model12.dta", clear 

//-------------------------------------------------------------------------------------------
//CASE SELECTION
//-------------------------------------------------------------------------------------------
sum nomem_encr 
//884475 cases

//STEP 1: SELECTING THE YOUTH 15-25
//Var indicating whether respondent is between the 15 and 25 years old.

gen select=1 if leeftijd >=15 & leeftijd <=25
drop if select==.
//dropped the cases about people older than 25 or younger than 15
sum nomem_encr 
xtdescribe
//124865 cases left, 3736 individuals

//STEP 2: SELECTING CASES WITHOUT MISSINGS & REMOVING OUTLIERS MODEL 1 PARTICIPATION
global list1 year geslacht belbezig oplmet
misstable tree $list1
tab belbezig 
drop if belbezig==.
//3 observations deleted, so 124.862 cases of 3.736 individuals


//-------------------------------------------------------------------------------------------
//DEPENDENT VARIABLE CONSTRUCTION
//-------------------------------------------------------------------------------------------
tab belbezig

gen labourforceparticipation=0
replace labourforceparticipation=1 if (employed==1 | unemployed==1)

tab labourforceparticipation
sum labourforceparticipation
tab labourforceparticipation leeftijd
bysort leeftijd: sum labourforceparticipation

//-------------------------------------------------------------------------------------------
//MISSING VALUE ANALYSIS / ATTRITION
//-------------------------------------------------------------------------------------------

/*T-TESTS 1 */

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

/*T-TESTS 2 */

// Check how much participants particiated through the years
sort nomem_encr
bysort newid: gen newid_count = _N
bysort nomem_encr: gen cases_count = _N

tab cases_count
sum cases_count
histogram cases_count, frequency
//141 of the 3736 individuals participated once ()
gen ttestvar=0
replace ttestvar=1 if cases_count==1
label variable ttestvar "Person only occurs once in nomem_encr"
ttest geslachtnew, by(ttestvar)
//significant differences between the groups in terms of gender

gen ttestvar1=0
replace ttestvar1=1 if cases_count==84
label variable ttestvar1 "Person only occurs less than 84 times in nomem_encr"
ttest geslachtnew, by(ttestvar1)
//significant differences between the groups in terms of gender


bysort leeftijd: tab year if newid_count==1 
tab leeftijd if newid_count==1 
tab temp if newid_count==1 
gen ttestvar2=0
replace ttestvar2=1 if newid_count==1
label variable ttestvar2 "Person only occurs once in newid"

ttest geslachtnew, by(ttestvar2)
//significant differences between the groups in terms of gender (the amount of females is lower in the newid_count==1)



tab ttestvar year
//especially 2015
tab temp year if ttestvar==1
//effect of 2015 is distributed between age-groups


//-------------------------------------------------------------------------------------------
//DESCRIPTIVES
//-------------------------------------------------------------------------------------------
sort nomem_encr
xtdescribe
sum nomem_encr
xtsum belbezig


gen timedummy17 = 1 if (year <= 2016) | (year== 2017 & month < 7)
tab datesurvey timedummy17

gen timedummy20 = 1 if (year > 2020) | (year== 2020 & month >= 7)
tab datesurvey timedummy20

gen timedummybetween = 1 if missing(timedummy17) & missing(timedummy20)
tab datesurvey timedummybetween


bysort temp timedummy17: sum labourforceparticipation
bysort temp timedummybetween: sum labourforceparticipation
bysort temp timedummy20: sum labourforceparticipation


//-------------------------------------------------------------------------------------------
//GRAPHS
//-------------------------------------------------------------------------------------------

tab agegroup labourforceparticipation

//Graph of labour force participation per agegroup (6 groups)
bysort agegroup year: egen participationmean = mean(labourforceparticipation)
tab participationmean agegroup
twoway (connected participationmean year if agegroup==1, sort) (connected participationmean year if agegroup==2, sort) (connected participationmean year if agegroup==3) (connected participationmean year if agegroup==4) (connected participationmean year if agegroup==5) (connected participationmean year if agegroup==6), xlabel(#7) xline(2018 2020) ytitle("%-being part of the labour force") legend(on) legend(label(1 "15-17 year olds") label(2 "18-19 year olds") label(3 "20 year olds") label(4 "21 year olds") label(5 "22 year olds") label(6 "23-25 year olds")) 
graph export "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Do files\labourforceparticipation\Graph_participation6.png", as(png) name("Graph") replace


//Graph of labour force participation per agegroup (3 groups)
bysort temp datesurvey: egen participationmean2 = mean(labourforceparticipation)
gen participationmean3 = participationmean2*100
tab participationmean3 agegroup
twoway (line participationmean3 datesurvey if temp==1, sort) (line participationmean3 datesurvey if temp==2, sort) (line participationmean3 datesurvey if temp==3, sort), tlabel(2015m1 "2015" 2016m1 "2016" 2017m1 "2017" 2018m1 "2018" 2019m1 "2019" 2020m1 "2020" 2021m1 "2021" 2022m1 "2022") ylabel(0(10)60) tline(2017m1, lpattern(shortdash)) tline(2017m7 2019m7, lwidth(0.5)) tline(2020m4, lpattern(dash_dot)) ytitle("%-being part of the labour force") xtitle("Time") legend(on) legend(label(1 "15-17 year olds") label(2 "18-22 year olds") label(3 "23-25 year olds")) 
graph export "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Do files\labourforceparticipation\Graph_participation3.png", as(png) name("Graph") replace


//-------------------------------------------------------------------------------------------
//ANALYSIS
//-------------------------------------------------------------------------------------------


pwcorr unemployment CPI timesinceevent temp, sig star(.05)
pwcorr temp timesinceevent, sig star(.05)

xtset newid datesurvey

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///2016 xtreg
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//base: 15-17 year olds, 2016
putdocx begin
putdocx save labourforceparticipation_model2016a.docx, replace
shell ren 'labourforceparticipation_model2016a.docx' 'labourforceparticipation_model2016a.doc'

xtreg labourforceparticipation ib9.timesinceevent ib1.temp announcement covid, base fe vce(cluster  nomem_encr)
outreg2 using labourforceparticipation_model2016a.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17a)

//base: 15-17 year olds, 2016 + interaction
xtreg labourforceparticipation ib9.timesinceevent ib1.temp announcement covid ib9.timesinceevent#ib1.temp, base fe vce(cluster  nomem_encr)
outreg2 using labourforceparticipation_model2016a.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17b)

//base: 23-25 year olds, 2016 
xtreg labourforceparticipation ib9.timesinceevent ib3.temp announcement covid, base fe vce(cluster  nomem_encr)
outreg2 using labourforceparticipation_model2016a.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25a)

//base: 23-25 year olds, 2016 + interaction
xtreg labourforceparticipation ib9.timesinceevent ib3.temp announcement covid ib9.timesinceevent#ib3.temp, base fe vce(cluster  nomem_encr)
outreg2 using labourforceparticipation_model2016a.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25b)


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//2017 xtreg
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//base: 15-17 year olds, 2017
putdocx begin
putdocx save labourforceparticipation_model2017a2017.docx, replace
shell ren 'labourforceparticipation_model2017a.docx' 'labourforceparticipation_model2017a.doc'

xtreg labourforceparticipation ib10.timesinceevent ib1.temp announcement covid, base fe vce(cluster  nomem_encr)
outreg2 using labourforceparticipation_model2017a.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17a)

//base: 15-17 year olds, 2017 + interaction
xtreg labourforceparticipation ib10.timesinceevent ib1.temp announcement covid ib10.timesinceevent#ib1.temp, base fe vce(cluster  nomem_encr)
outreg2 using labourforceparticipation_model2017a.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17b)

//base: 23-25 year olds, 2017 
xtreg labourforceparticipation ib10.timesinceevent ib3.temp announcement covid, base fe vce(cluster  nomem_encr)
outreg2 using labourforceparticipation_model2017a.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25a)

//base: 23-25 year olds, 2017 + interaction
xtreg labourforceparticipation ib10.timesinceevent ib3.temp announcement covid ib10.timesinceevent#ib3.temp, base fe vce(cluster  nomem_encr)
outreg2 using labourforceparticipation_model2017a.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25b)




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///2016 xtreg + announcement interaction
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//base: 15-17 year olds, 2016
putdocx begin
putdocx save labourforceparticipation_model2016b.docx, replace
shell ren 'labourforceparticipation_model2016b.docx' 'labourforceparticipation_model2016b.doc'

xtreg labourforceparticipation ib9.timesinceevent ib1.temp announcement covid, base fe vce(cluster  nomem_encr)
outreg2 using labourforceparticipation_model2016b.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17a)

//base: 15-17 year olds, 2016 + interaction
xtreg labourforceparticipation ib9.timesinceevent ib1.temp announcement covid ib9.timesinceevent#ib1.temp  b0.announcement##ib1.temp, base fe vce(cluster  nomem_encr)
outreg2 using labourforceparticipation_model2016b.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17b)

//base: 23-25 year olds, 2016 
xtreg labourforceparticipation ib9.timesinceevent ib3.temp announcement covid, base fe vce(cluster  nomem_encr)
outreg2 using labourforceparticipation_model2016b.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25a)

//base: 23-25 year olds, 2016 + interaction
xtreg labourforceparticipation ib9.timesinceevent ib3.temp announcement covid ib9.timesinceevent#ib3.temp b0.announcement##ib3.temp, base fe vce(cluster  nomem_encr)
outreg2 using labourforceparticipation_model2016b.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25b)


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//2017 xtreg + announcement interaction
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//base: 15-17 year olds, 2017
putdocx begin
putdocx save labourforceparticipation_model2017b2017.docx, replace
shell ren 'labourforceparticipation_model2017b.docx' 'labourforceparticipation_model2017b.doc'

xtreg labourforceparticipation ib10.timesinceevent ib1.temp announcement covid, base fe vce(cluster  nomem_encr)
outreg2 using labourforceparticipation_model2017b.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17a)

//base: 15-17 year olds, 2017 + interaction
xtreg labourforceparticipation ib10.timesinceevent ib1.temp announcement covid ib10.timesinceevent#ib1.temp  b0.announcement##ib1.temp, base fe vce(cluster  nomem_encr)
outreg2 using labourforceparticipation_model2017b.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17b)

//base: 23-25 year olds, 2017 
xtreg labourforceparticipation ib10.timesinceevent ib3.temp announcement covid, base fe vce(cluster  nomem_encr)
outreg2 using labourforceparticipation_model2017b.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25a)

//base: 23-25 year olds, 2017 + interaction
xtreg labourforceparticipation ib10.timesinceevent ib3.temp announcement covid ib10.timesinceevent#ib3.temp b0.announcement##ib3.temp, base fe vce(cluster  nomem_encr)
outreg2 using labourforceparticipation_model2017b.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25b)



log off
