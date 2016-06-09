***********************************************************************************************************************************
***********************************************************************************************************************************
macro_name: 	hshd_migration
author:				Brian Ritz
purpose:			find how many people migrated from each product group in each time period in a subset of the hshd summary dataset

PARAMETERS

input_dset : 									A dataset with hshd_id and one column denoting the product group and one column denoting the time period
															Each row represents an instance where that household purchased in the product group and time period specified in the line
															If the household did not purchase for a certain product group and time period, then that household-product group-time period 
																combination should not appear anywhere on the input dataset
															An easy way to achieve this is filtering the output dataset of the hshd summary macro for positive spend or for purchase_flag=1

outdset :											The output dataset for the migration numbers

product_id=product_id :				The name of the column that specifies the product id of the row

time_id=time_id:							The name of the column that specifies the time id of the row


***********************************************************************************************************************************
***********************************************************************************************************************************
;
%macro hshd_migration_help;

option NOQUOTELENMAX;
data _null_;

title "HSHD_MIGRATION MACRO";
title2 "Help Documentation";
file print ;
put 
"***********************************************************************************************************************************" /
"***********************************************************************************************************************************" /
"macro_name: 	hshd_migration" /
"author:		Brian Ritz" /
"purpose:	finds the number of customers who migrated between any number of product groups across any number of time periods" ///
"USE" //
"---"/
"The input dataset into the migration macro will have one row per hshd_id-product_group-time_period combination in which that"/"hshd actually purchased that product group in that time period."/
"If the household did not purchase the product group in that time period,"/"then that hshd_id-product_group-time period should not appear on the dataset"///
"EXAMPLE:"/"(hshd 123 purchased brandX in timeA but not timeB and purchased brandY in both timeA and timeB,"/" hshd 456 purchased brandX in timeA and timeB, and never purchased brandY):"///
"hshd_id	product_group	time_period"/
"123	brandX		timeA"/
"123	brandY		timeA"/
"123	brandY		timeB"/
"456	brandX		timeA"/
"456	brandX		timeB"///


"The easiest way to produce this type of input dataset is through the summarize_transactions_hhd macro also found in the macros"/"folder in the analyst toolkit on mount 0." / 
"The output of the summarize_transactions_hhd folder can be used as the input into the hshd_migration macro if you take where"/"purchase_flag = 1 or where spend > 0." ///
"OUTPUT"//
"------"/
"EXAMPLE:"/"product_id_a	product_id_b	time_id_a	time_id_b	n_a	n_stayed	n_added	n_dropped	n_b"/
"brandX		brandX		timeA		timeB		450	250		150	200		400"/
"brandX		brandY		timeA		timeB		450	100		200	350		300"///
"The output from this macro will be a sas dataset."/"Every row will have 4 columns identifying which product groups and time periods that row represents: "/"
	product_id_a, product_id_b, time_id_a, and time_id_b."///"Every combination of product groups and time periods will be represented by one row. "/"
5 customer counts will also be included for every row:"/
"	-n_a is the total number of customers who bought the product group indicated in product_id_a in time_period_a."/
"	-n_stayed is the number of customer who bought BOTH product_id_a in time_id_a  and product_id_b in time_id_b."/
"	-n_dropped is the number of customers who bought product_id_a in time_id_a, but did not purchase_product_id_b in time_id_b."/
"	-n_added is the number of customers who did not buy product_id_a in time_id_a but did purchase product_id_b in time_id_b."/
"	-n_b is the total number of customers who bought product_id_b in time_id_b."

_BLANKPAGE_
"PARAMETERS" //
"----------"/
"input_dset= :		A dataset with hshd_id and one column denoting the product group and one column denoting the time period"/
"			An easy way to achieve this is filtering the output dataset of the hshd summary macro"/"			for positive spend or for purchase_flag=1" ///
"outdset= :		The name of the output dataset for the migration numbers" ///

"product_id=product_id :	The name of the column that specifies the product id of the row"///

"time_id=time_id:	The name of the column that specifies the time id of the row"/

"***********************************************************************************************************************************"/
"***********************************************************************************************************************************"

;

run;
option QUOTELENMAX;

%mend;



%macro hshd_migration(input_dset, outdset, time_id=time_id, product_id=product_id);

proc sql noprint;
	create table _hshd_times_possible as select * from 
	((select distinct hshd_id from &input_dset.), (select distinct time_id from &input_dset.)) ;

	create table _hshd_time_unobserved as select * from
	_hshd_times_possible a left join (select distinct hshd_id, time_id from &input_dset.) b
	on a.hshd_id = b.hshd_id and a.&time_id. = b.&time_id.
	where b.hshd_id is null and b.&time_id. is null;

quit;

data _new_input_dset;
	set &input_dset.(in=a) _hshd_time_unobserved(in=b);
	if b then &product_id. = "NONE";
run;

proc sql noprint;
	select distinct &time_id. into : _all_time_ids separated by " " from _new_input_dset order by &time_id.;
	select distinct &product_id. into : _all_prod_ids separated by " " from _new_input_dset order by &product_id.;
quit;

%if %sysfunc(exist(&outdset.)) %then %do;
proc delete data=&outdset.;
run;
%end;


%put %sysfunc(countw(&_all_prod_ids.));
%put &_all_prod_ids.;
%do __g = 1 %to %sysfunc(countw(&_all_prod_ids.));
%do __h = 1 %to %sysfunc(countw(&_all_prod_ids.));
	%do __i = 1 %to %sysfunc(countw(&_all_time_ids.));
		%do __j = 1 %to %sysfunc(countw(&_all_time_ids.));

			%if &__i. ne &__j. %then %do;

				%let _prod1 = %scan(&_all_prod_ids., &__g.);
				%let _prod2 = %scan(&_all_prod_ids., &__h.);
				%let _time1 = %scan(&_all_time_ids, &__i.);
				%let _time2 = %scan(&_all_time_ids, &__j.);

				data _to_append(keep= &product_id._a &product_id._b &time_id._a &time_id._b n_added n_a n_b n_stayed n_dropped);
					/* set up variables */
					length &product_id._a &product_id._b &time_id._a &time_id._b $ 40;
					length n_a n_added n_dropped n_stayed n_b 8.;
					if 0 then set retention_inputs_test;

					/* hash table and hash iterator object */
					declare hash ht1 (ordered: 'a');
					declare hiter hi1 ('ht1');
					
					ht1.definekey ('hshd_id');
					ht1.definedone ();

					* construct the hash table from everyone in _time2 and _prod2;
					do until (eof2);
						set _new_input_dset(where=(&product_id.="&_prod2." and &time_id.="&_time2."))end = eof2;
						ht1.add();
					end;

					do until(eof);
						* set everyone from prod1 and time1 -- tick n_a for every observation;
						set _new_input_dset(keep=hshd_id &product_id. &time_id. where=(&product_id.="&_prod1." and &time_id.="&_time1."))end = eof;
						n_a = sum(n_a,1);

						if ht1.find() = 0 then do;
							n_stayed=sum(n_stayed,1);
							n_b=sum(n_b, 1);
							* if we find it -- that means it stayed..so we account for it in n_b and n_stayed and then delete it from the hash table;
							ht1.remove();
						end;
						else do;
							n_dropped=sum(n_dropped,1);
						end;
					end;
					* at this point all input dataset records have been read ;
					* Output remaining rows from the hash table;
					do _rc = hi1.first() by 0 while (_rc = 0);
						n_added=sum(n_added,1);
						n_b=sum(n_b,1);
						_rc = hi1.next();
					end;
					&product_id._a="&_prod1.";
					&product_id._b="&_prod2.";
					&time_id._a = "&_time1.";
					&time_id._b = "&_time2.";
					output;
					stop;
				run; 

				proc append base=&outdset. data=_to_append;
				run;

				%end;
		%end;
	%end;
%end;
%end;
proc datasets lib=work nolist;
	delete _to_append _new_input_dset _hshd_time_unobserved _hshd_times_possible;
run;

%mend;
