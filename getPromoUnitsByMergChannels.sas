libname dir_raw "C:\work\working materials\Materials for promo Mix\China\fromJiajing\output";
%let dataPath = C:\work\working materials\Materials for promo Mix\China\fromJiajing\output;

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

