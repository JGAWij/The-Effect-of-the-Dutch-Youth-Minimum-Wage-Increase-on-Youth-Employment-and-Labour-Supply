//search plotplain

ssc install outreg2
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

run "$path2\DataMangement_Model34.do"

use "$pathresults\LISS_Final_Cleaned2.dta", clear

//-------------------------------------------------------------------------------------------
//CASE SELECTION - MODEL 3
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
//4,521 cases, 1739 individuals

//STEP 2: SELECTING CASES WITHOUT MISSINGS & REMOVING OUTLIERS

//Making a list of the variables which will be used in the analysis
global list1 a127 year geslacht
misstable tree $list1
//36% of a127 is missing
drop if a127==.
sum nomem_encr 
xtdescribe
//2882 observations of 1379 individuals

//dep var: Average amount of hours working per week
tab a127
sum a127
label variable a127 "Average amount of hours working per week"
tab a127 a003
//Outlier seems to be present since working 111 hours per week on average is not possible

drop if a127>70
// 4 cases dropped
drop if a127==0
//303 cases dropped

sum nomem_encr 
xtdescribe
//2,577 observations of  1299 individuals

bysort a003: sum a127
//Although 15 year-olds are underrepresented, every age has a decent amount of observations
dotplot a127
//Seems not to be normally distributed 

histogram a127 if employed==1
histogram a127 if employed==0
//A lot of people stating that working is not their main task, work more than 40 hours per week on average 

sktest a127
//a127 is not normally distributed
sktest a127 if employed==1
//a127 is still not normally distributed


//generating the log of working hours
gen a127_log = ln(a127)
//by taking the log all people 

label variable a127_log "log of working hours"

histogram a127_log
histogram a127_log if employed==1
//if employed==1 distribution seems normal although some outliers in the left tail
sktest a127_log if employed==1
//but according to the test it is not normally distributed


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

sort nomem_encr
xtdescribe
sum nomem_encr
xtsum belbezig


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

ttest geslachtnew, by(ttestvar)
//significant differences between the groups in terms of gender (the amount of females is lower in the newid_count==1)

tab a003 ttestvar

//Checking cases and individuals based on newID
bysort nomem_encr: gen nomem_encr_count = _N
tab nomem_encr_count
histogram nomem_encr_count, frequency

//T-test
gen ttestvar1=0
replace ttestvar1=1 if nomem_encr_count==1
label variable ttestvar "Person only occurs once"

ttest geslachtnew, by(ttestvar1)

//T-test
gen ttestvar2=0
replace ttestvar2=1 if nomem_encr_count==7
label variable ttestvar "Person only occurs 7 times"

ttest geslachtnew, by(ttestvar2)

twoway histogram newid_count, color(ltblue) xlabel(1(1)7) frequency|| histogram nomem_encr_count, lcolor(black) fcolor(none) frequency legend(label(1 "New ID") label(2 "Nomem_encr"))


//-------------------------------------------------------------------------------------------
//DESCRIPTIVES
//-------------------------------------------------------------------------------------------
gen timedummy18 = 1 if year < 2018
gen timedummybetween = 1 if year < 2020 & year >= 2018
gen timedummy20 = 1 if year >= 2020


bysort temp timedummy18: sum a127
bysort temp timedummybetween: sum a127
bysort temp timedummy20: sum a127




//-------------------------------------------------------------------------------------------
//GRAPHS
//-------------------------------------------------------------------------------------------


//Graph of average amount of hours worked per week (3 groups)
bysort temp year: egen hoursworkedmean2 = mean(a127)
twoway (connected hoursworkedmean2 year if temp==1, sort) (connected hoursworkedmean2 year if temp==2, sort) (connected hoursworkedmean2 year if temp==3), xlabel(#7) xline(2018 2020) ylabel(0(5)35) ytitle("Number of working hours") legend(on) legend(label(1 "15-17 year olds") label(2 "18-22 year olds") label(3 "23-25 year olds"))  
graph export "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Do files\Working hours\Graph_workinghours3.png", as(png) name("Graph") replace

//Graph of average amount of hours worked per week (6 groups)
bysort agegroup year: egen hoursworkedmean = mean(a127)
twoway (connected hoursworkedmean year if agegroup==1, sort) (connected hoursworkedmean year if agegroup==2, sort) (connected hoursworkedmean year if agegroup==3) (connected hoursworkedmean year if agegroup==4) (connected hoursworkedmean year if agegroup==5) (connected hoursworkedmean year if agegroup==6), xlabel(#7) ylabel(0(5)35) ytitle("Number of working hours") legend(on) legend(label(1 "15-17 year olds") label(2 "18-19 year olds") label(3 "20 year olds") label(4 "21 year olds") label(5 "22 year olds") label(6 "23-25 year olds")) 
graph export "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Do files\Working hours\Graph_workinghours6.png", as(png) name("Graph") replace

//Graph representing unemployment and ICP
twoway (connected unemployment year, sort) (connected CPI year, sort), xlabel(#7) ytitle("Average Unemployment or Change in CPI in %") legend(on)
graph export "\\Client\C$\Users\jesse\OneDrive\Documenten\2021-2022\Thesis\Do files\Working hours\Graph_Controls.png", as(png) name("Graph") replace

tab temp year

//-------------------------------------------------------------------------------------------
//ANALYSIS
//-------------------------------------------------------------------------------------------

xtset newid year

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///2016 xtreg
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
putdocx begin
putdocx save workinghours_model2016.docx, replace
shell ren 'workinghours_model2016.docx' 'workinghours_model2016.doc'

//base: 15-17 year olds, 2016
xtreg a127_log ib9.timesinceevent ib1.temp covid, base cluster(nomem_encr) fe
outreg2 using workinghours_model2016.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17a)

//base: 15-17 year olds, 2016 + interaction
xtreg a127_log ib9.timesinceevent ib1.temp covid ib9.timesinceevent#ib1.temp, base cluster(nomem_encr) fe
outreg2 using workinghours_model2016.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17b)

//base: 23-25 year olds, 2016 
xtreg a127_log ib9.timesinceevent ib3.temp covid, base cluster(nomem_encr) fe
outreg2 using workinghours_model2016.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25a)

//base: 23-25 year olds, 2016 + interaction
xtreg a127_log ib9.timesinceevent ib3.temp covid ib9.timesinceevent#ib3.temp, base cluster(nomem_encr) fe 
outreg2 using workinghours_model2016.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25b)
//model 1 (fixed effects)




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//2017 xtreg
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

putdocx begin
putdocx save workinghours_model2017.docx, replace
shell ren 'workinghours_model2017.docx' 'workinghours_model2017.doc'

//base: 15-17 year olds, 2017
xtreg a127_log ib10.timesinceevent ib1.temp covid, base cluster(nomem_encr) fe
outreg2 using workinghours_model2017.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17a)

//base: 15-17 year olds, 2017 + interaction
xtreg a127_log ib10.timesinceevent ib1.temp covid ib10.timesinceevent#ib1.temp, base cluster(nomem_encr) fe 
outreg2 using workinghours_model2017.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 15-17b)


//base: 23-25 year olds, 2017 
xtreg a127_log ib10.timesinceevent ib3.temp covid, base cluster(nomem_encr) fe
outreg2 using workinghours_model2017.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25a)

//base: 23-25 year olds, 2017 + interaction
xtreg a127_log ib10.timesinceevent ib3.temp covid ib10.timesinceevent#ib3.temp, base cluster(nomem_encr) fe 
outreg2 using workinghours_model2017.doc, append word alpha(0.01, 0.05, 0.10) sym(***, **, *) ctitle(Model 23-25b)


pause on
pause

log off

/* 


TO DO
- checken aantal cases per categorie in interactie
- imputed an income of zero for nonemployed people
- Checken verdeling uren werk (checken andere artikelen hierover)
- effect op voluntary work / attends school
- work & schooling induiken: cw20m126: uren voor de hoofdbaan, cw20m127: uren gemiddeld gewerkt wordt, cw20m145: hoeveel uur zou u willen werken per week, cw20m128: tevredenheid loon, 
- check for proxy interviews / measurement error over there and whether this is random
- The summary statistics and regression results are estimated using
sampling weights created by Statistics New Zealand to increase the representativeness of the
samples to take account of the sample frame and non-random survey response and individual
attrition. (HYSLOP STILLMAN 2007)
- controlegroepen vergelijken: hoe sterk correleren ze? 

-----------------------------------------------------
Trash
-----------------------------------------------------

https://reader.elsevier.com/reader/sd/pii/S009411902200002X?token=D1D92FE133983C529E2C115DD64F666253A604E1969C4EB4C904CDD067C25C78218FDE5C6F4004A0BFA65C54BF950537&originRegion=eu-west-1&originCreation=20220521093806

cw20m121
[if cw20m088=1 or cw20m102=1: Bent u werknemer in vaste of tijdelijke dienst,
oproepkracht, uitzendkracht of bent u een zelfstandige/freelancer of vrij
beroepsbeoefenaar? / if cw20m089=1 or cw20m091=1 or cw20m092=1 or
cw20m103=1 or cw20m098=1:

cw20m121
[if cw20m088=1 or cw20m102=1: Bent u werknemer in vaste of tijdelijke dienst,
oproepkracht, uitzendkracht of bent u een zelfstandige/freelancer of vrij
beroepsbeoefenaar?

cw20m088 berricht betaald werk

cw20m095 ik ben scholier

search putdocx
search mdesc

tab a525

https://www.youtube.com/watch?v=Fb4RzzG6moE

https://www.youtube.com/watch?v=QCqF-2E86r0

//quasi experimental, dif en dif --> controleren / toevoegen
//counter factual: controls geven aan wat er met de treatment gebeurd als het niet gebeurd
//omitted variable bias: fixed effects voor individuen --> herkomst/gezin
// meenemen of de interactie effecten veranderen wel of niet
//vergelijkingen tussen modellen fixed effects en ols
//unemployment of inflactie --> belangrijkste controle



