%let date=20180115_1;

libname dir_raw "C:\work\working materials\Materials for promo Mix\China\fromJiajing\output";
libname sasout "C:\work\working materials\Materials for promo Mix\China\03 Results\sas\&date.";
libname sales "C:\work\working materials\Materials for promo Mix\China\01 Data";
%let dataPath = C:\work\working materials\Materials for promo Mix\China\fromJiajing\output;
%let dataPath1 = C:\work\working materials\Materials for promo Mix\China\03 Results\2017-12-21 12.03.17;
%let outPath = C:\work\working materials\Materials for promo Mix\China\03 Results\sas\&date.;
%let salesPath= C:\work\working materials\Materials for promo Mix\China\01 Data;

/*proc import out=dir_raw.details*/
/*datafile="&dataPath\Detailing.csv"*/
/*dbms=csv replace;*/
/*GUESSINGROWS=1321075;*/
/*run;*/

data details;
set dir_raw.details;
run;
proc import out=mails
datafile="&dataPath\Mailing.csv"
dbms=csv replace;
run;

proc import out=meetings
datafile="&dataPath\Meeting.csv"
dbms=csv replace;
run;

proc import out=onekey_hosp
datafile="&dataPath\onekey_hosp.csv"
dbms=csv replace;
run;

proc import out=spec_ref
datafile="&dataPath1\spec_matched_withManualChange_addJiajing.csv"
dbms=csv replace;
run;

proc import out=spec_ref_code
datafile="&dataPath\spec_ref.csv"
dbms=csv replace;
run;

data spec_ref_code;
length specialty $ 30;
set spec_ref_code;
run;

data spec_ref;
length spec_reference_manual_change__ad $30;
set spec_ref;
run;

proc sql;
create table spec_ref_addCode as
select a.spec_reference, a.spec_reference_manual_change__ad as spec_details,b.promo_spe_code
from spec_ref a left join spec_ref_code b
on a.spec_reference=b.specialty;
quit;

proc sql;
create table details as
select a.*, b.promo_spe_code as specialty
from details a left join spec_ref_addCode b
on a.Promo_Specialty=b.spec_details;
quit;

/*check the spec code merge*/
proc sql;
create table check_spec_merge as
select distinct promo_specialty from details 
where specialty=.;
quit;

proc sql;
select distinct promo_specialty from details;
quit;

proc sql;
select distinct spec_details from spec_ref_addCode;
quit;
data details;
set details;
related_date1 = input(related_date,yymmdd10.);
if _n_=1 then do;
call symput('spec_promo', Promo_Specialty);
end;
/*related_date2=trim(related_date);*/
run;
%put &spec_promo.&date.;
data details;
set details;
department_code1=department_code+0;

drop department_code;
rename department_code1=department_code;
run;

/*data temp;*/
/*set spec_ref;*/
/*if _n_=1 then do;*/
/*call symput('spec_ref', spec_ref_changed);*/
/*end;*/
/*related_date2=trim(related_date);*/
/*run;*/
/*%put &spec_ref.&date.;*/
/*%put &date;*/
/**/
/*data temp;*/
/*set spec_ref;*/
/*test="tt"||strip(spec_ref_changed)||"tt";*/
/*spec_ref_changed1=strip(spec_ref_changed);*/
/*cat = spec_ref_changed1||"tt";*/
/*run;*/

/*proc sql;*/
/*select distinct Promo_Specialty from details;*/
/*quit;*/
/**/
/**/
/*proc sql;*/
/*select distinct specialty from spec_ref;*/
/*quit;*/

%let seg_name = department_code;
/*%let seg_name = speciality;*/

data details;
set details;
rename specialty=speciality;
run;

%macro merge_promo_units(seg_name);
proc sql;
create table seg_all as
select distinct &seg_name. from details /*specialty*/
union
select distinct &seg_name. from mails /*Speciality*/
union
select distinct &seg_name. from meetings; /*Speciality*/
quit;


proc sql;
create table mail_1 as
select &seg_name., count(*)
from mails
group by &seg_name.;
quit;

proc sql;
create table seg_det_1 as
select seg_all.&seg_name., details_unit.related_date, details_unit.units_details
from seg_all left join
(select &seg_name., related_date1 as related_date, count(*) as units_details from details group by &seg_name., related_date1) details_unit
on seg_all.&seg_name.=details_unit.&seg_name.;
quit;

proc sql;
select sum(units_details) from seg_det_1;
quit;
/*1321075 
*/
/**/
/*proc sql;*/
/*create table seg_det_mail_1 as*/
/*select a.*, mails_unit.units_mails*/
/*from*/
/*(select seg_all.&seg_name., details_unit.related_date, details_unit.units_details*/
/*from seg_all left join*/
/*(select &seg_name., related_date1 as related_date, count(*) as units_details from details group by &seg_name., related_date1) details_unit*/
/*on seg_all.&seg_name.=details_unit.&seg_name.) a*/
/*left join (select &seg_name., related_date, count(*) as units_mails from mails group by &seg_name., related_date) mails_unit*/
/**/
/*on a.&seg_name.=mails_unit.&seg_name. and a.related_date=mails_unit.related_date;*/
/*quit;*/

proc sql;
create table mail_2 as
select &seg_name., related_date, count(*) as units_mails from mails group by &seg_name., related_date;

quit;

proc sql;
create table meeting_2 as
select &seg_name., related_date, count(*) as units_meetings from meetings group by &seg_name., related_date;

quit;



proc sql;
create table tt3 as
select seg_det_1.&seg_name. as &seg_name._1
, seg_det_1.related_date as related_date_1
, seg_det_1.units_details
, mail_2.&seg_name. as &seg_name._2
, mail_2.related_date as related_date_2
, mail_2.units_mails
from seg_det_1 full outer join mail_2
on seg_det_1.&seg_name. = mail_2.&seg_name. and seg_det_1.related_date=mail_2.related_date;
quit;

data tt3;
set tt3;
format related_date_1 MMDDYY10.;
format related_date_2 MMDDYY10.;

run;

data tt4;
retain &seg_name. related_date units_details units_mails;
set tt3;
if &seg_name._1^=. then &seg_name.=&seg_name._1;else &seg_name.=&seg_name._2;
if related_date_1 ^=. then related_date=related_date_1;else related_date=related_date_2;
format related_date MMDDYY10.;
keep &seg_name. related_date units_details units_mails;
run;

proc sql;
create table tt5 as
select &seg_name., sum(units_details) as sum_details, sum(units_mails) as sum_mails
from tt4
group by &seg_name.;
quit;

proc sql;
select sum(sum_details), sum(sum_mails) from tt5;
quit;


proc sql;
create table tt6 as
select a.&seg_name. as &seg_name._1
, a.related_date as related_date_1
, a.units_details
, a.units_mails
, b.&seg_name. as &seg_name._2
, b.related_date as related_date_2
, b.units_meetings
from tt4 a full join meeting_2 b
on a.&seg_name.=b.&seg_name. and a.related_date=b.related_date;
quit;

data tt7;
retain &seg_name. related_date units_details units_mails units_meetings;
set tt6;
if &seg_name._1^=. then &seg_name.=&seg_name._1;else &seg_name.=&seg_name._2;
if related_date_1 ^=. then related_date=related_date_1;else related_date=related_date_2;
format related_date MMDDYY10.;
keep &seg_name. related_date units_details units_mails units_meetings;
run;

proc sql;
create table tt8 as
select &seg_name., sum(units_details) as sum_details, sum(units_mails) as sum_mails
, sum(units_meetings) as sum_meetings
from tt7
group by &seg_name.;
quit;

proc sql;
select sum(sum_details) as sum_details, sum(sum_mails) as sum_mails, sum(sum_meetings) as sum_meetings from tt8;
quit;

/*sum_details sum_mails sum_meetings 
1321075 9333 54479 
 */

data sasout.promo_data_&seg_name.;
set tt7;
run;

data sasout.check_rollup_by_&seg_name.;
set tt8;
run;

proc sql;
select * from sasout.promo_data_&seg_name.
where units_details=. and units_mails=. and units_meetings=.;
run;
/*0 records*/

proc export data=sasout.promo_data_&seg_name.
outfile="&outPath.\promo_data_&&seg_name._&date..csv"
dbms=csv replace;
run;

proc export data=sasout.check_rollup_by_&seg_name.
outfile="&outPath.\check_rollup_by_&seg_name..csv"
dbms=csv replace;
run;

/*check the month number of each segment(i.e. department_code)*/
proc sql;
create table sasout.check_n_month_&seg_name. as
select &seg_name., count(distinct related_date) as n_uniq_month
from sasout.promo_data_&seg_name.
group by &seg_name.;
quit;

proc export data=sasout.check_n_month_&seg_name.
outfile="&outPath.\check_n_month_&seg_name..csv"
dbms=csv replace;
run;



%mend;

%merge_promo_units(&seg_name.);


/*join with sales data*/
proc import out=sales.sales_bySpec
datafile="&salesPath\sales_bySpec_new.csv"
dbms=csv replace;
run;

proc import out=sales.sales_byCity
datafile="&salesPath\sales_byCity_new.csv"
dbms=csv replace;
run;


proc sql;
select distinct promo_spe_code from sales.sales_bySpec;
quit;

proc sql;
select distinct Department_code from sales.sales_byCity;
quit;

/*proc sql;*/
/*create table promo_sales_&seg_name. as*/
/*select a.*, b.STANDARD_UNITS*/
/*from sasout.promo_data_&seg_name. a left join sales.sales_bySpec b*/
/*on a.&seg_name. = b.promo_spe_code;*/
/*quit;*/

proc sql;
create table promo_sales_&seg_name. as
select a.*, b.STANDARD_UNITS
from sasout.promo_data_&seg_name. a left join sales.sales_byCity b
on a.&seg_name. = b.&seg_name.;
quit;

proc sql;
create table &seg_name._notinsales as
select distinct &seg_name. from promo_sales_&seg_name.
where standard_units = .;
quit;

proc export data=&seg_name._notinsales
outfile="&outPath.\&seg_name._notInSales.csv"
dbms=csv replace;
run;

/**/
proc sql;
create table sasout.promo_sales_&seg_name._valid as
select a.*, b.STANDARD_UNITS
from sasout.promo_data_&seg_name. a left join sales.sales_bySpec b
on a.&seg_name. = b.promo_spe_code
where b.standard_units^=. and a.&seg_name.^=.;
quit;
/*8330*/

proc sql;
create table sasout.promo_sales_dep_valid as
select a.*, b.STANDARD_UNITS
from sasout.promo_data_&seg_name. a left join sales.sales_byCity b
on a.&seg_name. = b.&seg_name.
where b.standard_units^=. and a.&seg_name.^=.;
quit;
/*15470*/

proc sql;
select distinct &seg_name. from promo_sales_&seg_name._valid;
quit;
/*7 specialty types*/

