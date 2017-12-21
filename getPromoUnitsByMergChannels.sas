%let date=20171218;

libname dir_raw "C:\work\working materials\Materials for promo Mix\China\fromJiajing\output";
%let dataPath = C:\work\working materials\Materials for promo Mix\China\fromJiajing\output;
%let outPath = C:\work\working materials\Materials for promo Mix\China\03 Results;
/*%let outPath1 = C:\work\working materials\Materials for promo Mix\China\03 Results;*/

* DATA Step;
/*data _null_;  */
/*    datetime = datetime();*/
/*    put datetime= datetime18.;*/
/*	call symput('currdate', datetime);*/
/*run;*/
/*%put &currdate.;*/

/*%let timestamp = %sysfunc(time(),timeampm.) on %sysfunc(date(),worddate.).;*/
/*%let resultDir = &outPath1.\&timestamp.;*/
/*%put &resultDir.;*/
/*%let newdir=%sysfunc(dcreate(&resultDir., ''));*/
/*%put &newdir;*/
/*x "mkdir &resultDir";*/
/*x "mkdir c:\mypath\&yrmo\excel";*/

proc import out=details
datafile="&dataPath\Detailing.csv"
dbms=csv replace;
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

data details;
set details;
related_date1 = input(related_date,yymmdd10.);
/*related_date2=trim(related_date);*/
run;

/*at onekey_id level*/
proc sql;
create table promo_data_details as
select a.usrtvf as onekey_id, b.related_date1 as related_date, b.units_details
from onekey_hosp a left join 
(select onekey_id, related_date1, count(*) as units_details from details group by onekey_id, related_date1) b
on a.usrtvf=b.onekey_id;
quit;

/* 117122 rows and 3 columns*/

proc sql;
create table promo_data as
select c.*, d.units_meetings 
from
(select a.*, b.units_mails
from promo_data_details a left join (select onekey_id, related_date, count(*) as units_mails from mails group by onekey_id, related_date) b
on a.onekey_id=b.onekey_id and a.related_date=b.related_date) c
left join (select onekey_id, related_date, count(*) as units_meetings from meetings group by onekey_id, related_date) d
on c.onekey_id=d.onekey_id and c.related_date=d.related_date;
quit;

data promo_data;
set promo_data;
 format related_date mmddyy10.;
run;

/*at speicialty level*/
proc sql;
create table promo_data_details as
select a.usrtvf as onekey_id, b.related_date1 as related_date, b.units_details
from onekey_hosp a left join 
(select onekey_id, related_date1, count(*) as units_details from details group by onekey_id, related_date1) b
on a.usrtvf=b.onekey_id;
quit;

/* 117122 rows and 3 columns*/

%let seg_name=department_code;
data details;
set details;
department_code1=department_code+0;
drop department_code;
rename department_code1=department_code;
run;
proc sql;
create table promo_data as
select c.*, d.units_meetings 
from
(select a.*, b.units_mails
from promo_data_details a left join (select &seg_name., related_date, count(*) as units_mails from mails group by &seg_name., related_date) b
on a.&seg_name.=b.&seg_name. and a.related_date=b.related_date) c
left join (select &seg_name., related_date, count(*) as units_meetings from meetings group by &seg_name., related_date) d
on c.&seg_name.=d.&seg_name. and c.related_date=d.related_date;
quit;

proc sql;
create table seg_all as
select distinct &seg_name. from details
union
select distinct &seg_name. from mails
union
select distinct &seg_name. from meetings;
quit;

proc sql;
create table promo_data_&seg_name. as
select b.*, meetings_unit.units_meetings
from
(select a.*, mails_unit.units_mails
from
(select seg_all.&seg_name., details_unit.related_date, details_unit.units_details
from seg_all left join
(select &seg_name., related_date1 as related_date, count(*) as units_details from details group by &seg_name., related_date1) details_unit
on seg_all.&seg_name.=details_unit.&seg_name.) a
left join (select &seg_name., related_date, count(*) as units_mails from mails group by &seg_name., related_date) mails_unit

on a.&seg_name.=mails_unit.&seg_name. and a.related_date=mails_unit.related_date) b
left join (select &seg_name., related_date, count(*) as units_meetings from meetings group by &seg_name., related_date) meetings_unit
on b.&seg_name.=meetings_unit.&seg_name. and b.related_date=meetings_unit.related_date;
quit;


data promo_data_&seg_name.;
set promo_data_&seg_name.;
 format related_date mmddyy10.;
run;

proc export data=promo_data_&seg_name.
outfile="&outPath.\promo_data_&&seg_name._&date..csv"
dbms=csv replace;
run;

/*check*/
proc sql;
select distinct &seg_name. from promo_data_&seg_name.;
quit;
/*15 including NA*/
proc sql;
select sum(units_details) as sum_details
, sum(units_mails) as sum_mails
, sum(units_meetings) as sum_meetings
from promo_data_&seg_name.;
quit;
/*sum_details sum_mails sum_meetings 
1321075 9302 54343 
*/

proc sql;
create table check_sumUnits_by_dept as
select &seg_name., sum(units_mails) as sum_mails
, sum(units_meetings) as sum_meetings
from promo_data_&seg_name.
group by &seg_name.;
quit;


proc sql;
select sum(units_details) as sum_details
, sum(units_mails) as sum_mails
, sum(units_meetings) as sum_meetings
from promo_data;
quit;
/*sum_details sum_mails sum_meetings 
1416578 9673 54128 
*/

proc sql;
create table check_sumUnits_by_onekey as
select onekey_id, sum(units_mails) as sum_mails
, sum(units_meetings) as sum_meetings
from promo_data
group by onekey_id;
quit;

