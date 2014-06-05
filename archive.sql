.mode csv
.headers on
.output dataset.csv
select * from dataset;
.output value.csv
select dsID,region,indID,period,value,is_number from value;
.output indicator.csv
select * from indicator;
.output all.sql
.dump
