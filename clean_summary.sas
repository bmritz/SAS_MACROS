***********************************************************************************************************************************
***********************************************************************************************************************************
macro_name: 	clean_summary
author:				Brian Ritz
purpose:			clean the ancova summary dataset that comes from exadata and add on the correct formats for every variable

parameters:

data: 								input dset that you wish to create formats from
out: 							name of the output dataset you wish to create
euom_change:			what you would like to replace euom with in the variable name -- defaults to EUOM
metric_name_var:		the name fo the variable that gives the metric name -- defaults to variable_name
***********************************************************************************************************************************
***********************************************************************************************************************************
;

%macro clean_summary(data=, out=, euom_change=EUOM, metric_name=variable_name);

%if &out.=%str() %then %let out=&data.;

data &out.(drop=&metric_name. rename=(value2=clean_value &metric_name.2=&metric_name.));
	set &data.;
	length value2 $100;
	length &metric_name.2 $100;
	label value2 = "Value" &metric_name.2="Variable Name";
if upcase(&metric_name.)='BUYING CUSTOMERS' 								then do; value2 = strip(put(value, comma20.-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='COUPON SPEND' 										then do; value2 = strip(put(round(value, 0.01), dollar18.2-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='COUPON SPEND PER BUYING HSHD' 		then do; value2 = strip(put(round(value, 0.01), dollar20.2-l)); &metric_name.2="Coupon Spend Per Buying Household"; end;
else if upcase(&metric_name.)='COUPON SPEND PER HSHD' 						then do; value2 = strip(put(round(value, 0.01), dollar20.2-l)); &metric_name.2="Coupon Spend Per Household"; end;
else if upcase(&metric_name.)='COUPON UNITS' 										then do; value2 = strip(put(value, comma20.-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='COUPON UNITS PER BUYING HSHD' 		then do; value2 = strip(put(round(value, 0.01), comma22.2-l)); &metric_name.2="Coupon Units Per Buying Household"; end;
else if upcase(&metric_name.)='COUPON UNITS PER HSHD' 						then do; value2 = strip(put(round(value, 0.01), comma22.2-l)); &metric_name.2="Coupon Units Per Household"; end;
else if upcase(&metric_name.)='DISCOUNT SPEND' 									then do; value2 = strip(put(round(value, 0.01), dollar20.2-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='DISCOUNT SPEND PER BUYING HSHD' 	then do; value2 = strip(put(round(value, 0.01), dollar20.2-l)); &metric_name.2="Discount Spend Per Buying Household"; end;
else if upcase(&metric_name.)='DISCOUNT SPEND PER HSHD' 					then do; value2 = strip(put(round(value, 0.01), dollar20.2-l)); &metric_name.2="Discount Spend Per Household"; end;
else if upcase(&metric_name.)='DISCOUNT UNITS' 									then do; value2 = strip(put(value, comma22.-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='DISCOUNT UNITS PER BUYING HSHD' 	then do; value2 = strip(put(round(value, 0.01), comma22.2-l)); &metric_name.2="Discount Units Per Buying Household"; end;
else if upcase(&metric_name.)='DISCOUNT UNITS PER HSHD' 					then do; value2 = strip(put(round(value, 0.01), comma22.2-l)); &metric_name.2="Discount Units Per Household"; end;
else if upcase(&metric_name.)='EUOM' 														then do; value2 = strip(put(round(value, 0.01), comma22.2-l)); &metric_name.2="&euom_change."; end;
else if upcase(&metric_name.)='EUOM PER BUYING HSHD' 						then do; value2 = strip(put(round(value, 0.01), comma22.2-l));	&metric_name.2="&euom_change. Per Buying Household"; end;
else if upcase(&metric_name.)='EUOM PER HSHD' 										then do; value2 = strip(put(round(value, 0.01), comma22.2-l));	&metric_name.2="&euom_change. Per Household"; end;
else if upcase(&metric_name.)='EUOM PER UNIT' 										then do; value2 = strip(put(round(value, 0.01), comma22.2-l));	&metric_name.2="&euom_change. Per Unit";	end;
else if upcase(&metric_name.)='EUOM PER VISIT' 									then do; value2 = strip(put(round(value, 0.01), comma22.2-l));	&metric_name.2="&euom_change. Per Visit"; end;
else if upcase(&metric_name.)='FULL SPEND' 											then do; value2 = strip(put(round(value, 0.01), dollar20.2-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='FULL SPEND PER BUYING HSHD' 			then do; value2 = strip(put(round(value, 0.01), dollar20.2-l)); &metric_name.2="Full Spend Per Buying Household"; end;
else if upcase(&metric_name.)='FULL SPEND PER HSHD' 							then do; value2 = strip(put(round(value, 0.01), dollar20.2-l)); &metric_name.2="Full Spend Per Household"; end;
else if upcase(&metric_name.)='PCT SPEND ON COUPON' 							then do; value2 = strip(put(round(value, 0.0001), percent20.2-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='PCT SPEND ON DISCOUNT' 						then do; value2 = strip(put(round(value, 0.0001), percent20.2-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='PCT UNITS ON COUPON' 							then do; value2 = strip(put(round(value, 0.0001), percent20.2-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='PCT UNITS ON DISCOUNT' 						then do; value2 = strip(put(round(value, 0.0001), percent20.2-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='PENETRATION' 											then do; value2 = strip(put(round(value, 0.0001), percent20.2-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='SOR BLENDED' 											then do; value2 = strip(put(round(value, 0.01), percent20.-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='SOR EUOM' 												then do; value2 = strip(put(round(value, 0.01), percent20.-l)); &metric_name.2="Sor &euom_change."; end;
else if upcase(&metric_name.)='SOR SPEND' 												then do; value2 = strip(put(round(value, 0.01), percent20.-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='SOR UNITS' 												then do; value2 = strip(put(round(value, 0.01), percent20.-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='SPEND' 														then do; value2 = strip(put(round(value, 0.01), dollar20.2-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='SPEND PER BUYING HSHD' 						then do; value2 = strip(put(round(value, 0.01), dollar20.2-l)); &metric_name.2="Spend Per Buying Household"; end;
else if upcase(&metric_name.)='SPEND PER EUOM' 									then do; value2 = strip(put(round(value, 0.01), dollar20.2-l)); &metric_name.2="Spend Per &euom_change."; end;
else if upcase(&metric_name.)='SPEND PER HSHD' 									then do; value2 = strip(put(round(value, 0.01), dollar20.2-l)); &metric_name.2="Spend Per Household"; end;
else if upcase(&metric_name.)='SPEND PER UNIT' 									then do; value2 = strip(put(round(value, 0.01), dollar20.2-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='SPEND PER VISIT' 									then do; value2 = strip(put(round(value, 0.01), dollar20.2-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='TOTAL CUSTOMERS' 									then do; value2 = strip(put(value, comma20.-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='UNITS' 														then do; value2 = strip(put(value, comma20.-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='UNITS PER BUYING HSHD' 						then do; value2 = strip(put(round(value, 0.01), comma20.2-l)); &metric_name.2="Units Per Buying Household"; end;
else if upcase(&metric_name.)='UNITS PER HSHD' 									then do; value2 = strip(put(round(value, 0.01), comma20.2-l)); &metric_name.2="Units Per Household"; end;
else if upcase(&metric_name.)='UNITS PER VISIT' 									then do; value2 = strip(put(round(value, 0.01), comma20.2-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='VISITS' 													then do; value2 = strip(put(value, comma20.-l)); &metric_name.2=&metric_name.; end;
else if upcase(&metric_name.)='VISITS PER BUYING HSHD' 					then do; value2 = strip(put(round(value, 0.01), comma20.2-l)); &metric_name.2="Visits Per Buying Household"; end;
else if upcase(&metric_name.)='VISITS PER HSHD' 									then do; value2 = strip(put(round(value, 0.01), comma20.2-l)); &metric_name.2="Visits Per Household"; end;
else do; value2 = put(round(value, 0.0001), $best20.-l); &metric_name.2 = &metric_name.; end;
run;
	
***RECORD USE;
%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/record.sas";
%let __mname = %nrquote(&sysmacroname.);
%record(&__mname.);
***;
%mend;

%macro clean_ancova(data=, out=, euom_change=EUOM, metric_name=variable_name, control_label=Control, test_label=CRM Members);

%if &out.=%str() %then %let out=&data.;

data &out.(
	drop=&metric_name. _i test_mean control_mean uplift_mean uplift_pct test_unadjusted_post test_unadjusted_pre cont_unadjusted_post cont_unadjusted_pre
	rename=(test_mean2=test_mean 
			control_mean2=control_mean
			test_unadjusted_post2=test_unadjusted_post	
			test_unadjusted_pre2=test_unadjusted_pre	
			cont_unadjusted_post2=cont_unadjusted_post	
			cont_unadjusted_pre2=cont_unadjusted_pre
			uplift_mean2=uplift_mean uplift_pct2=uplift_pct
 			&metric_name.2=&metric_name.)
			);
	set &data.;
	array _or {7} test_mean control_mean uplift_mean test_unadjusted_post test_unadjusted_pre cont_unadjusted_post cont_unadjusted_pre;
	array _nw {7} $100 test_mean2 control_mean2 uplift_mean2 test_unadjusted_post2 test_unadjusted_pre2 cont_unadjusted_post2 cont_unadjusted_pre2;
	length &metric_name.2 $100;
	label  &metric_name.2="Variable Name" test_mean2="&test_label. Mean" control_mean2="&control_label. Mean"
			test_unadjusted_post2="&test_label. Unadjusted Post" test_unadjusted_pre2="&test_label. Unadjusted Pre"
			cont_unadjusted_post2 = "&control_label. Unadjusted Post" cont_unadjusted_pre2="&control_label. Unadjusted Pre"
			stat_test ="Significance Test" pvalue="PValue" control_n="&control_label. N" test_n="&test_label. N";
uplift_pct2 = put(round(uplift_pct, 0.0001), percentn8.2 -l);
do _i = 1 to 7;
if upcase(&metric_name.)='BUYING CUSTOMERS' 								then do; _nw[_i] = put(_or[_i], comma20. -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='COUPON SPEND' 										then do; _nw[_i] = put(round(_or[_i], 0.01), dollar18.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='COUPON SPEND PER BUYING HSHD' 		then do; _nw[_i] = put(round(_or[_i], 0.01), dollar20.2 -l); &metric_name.2="Coupon Spend Per Buying Household"; end;
if upcase(&metric_name.)='COUPON SPEND PER HSHD' 						then do; _nw[_i] = put(round(_or[_i], 0.01), dollar20.2 -l); &metric_name.2="Coupon Spend Per Household"; end;
if upcase(&metric_name.)='COUPON UNITS' 										then do; _nw[_i] = put(_or[_i], comma20. -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='COUPON UNITS PER BUYING HSHD' 		then do; _nw[_i] = put(round(_or[_i], 0.01), comma22.2 -l); &metric_name.2="Coupon Units Per Buying Household"; end;
if upcase(&metric_name.)='COUPON UNITS PER HSHD' 						then do; _nw[_i] = put(round(_or[_i], 0.01), comma22.2 -l); &metric_name.2="Coupon Units Per Household"; end;
if upcase(&metric_name.)='DISCOUNT SPEND' 									then do; _nw[_i] = put(round(_or[_i], 0.01), dollar20.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='DISCOUNT SPEND PER BUYING HSHD' 	then do; _nw[_i] = put(round(_or[_i], 0.01), dollar20.2 -l); &metric_name.2="Discount Spend Per Buying Household"; end;
if upcase(&metric_name.)='DISCOUNT SPEND PER HSHD' 					then do; _nw[_i] = put(round(_or[_i], 0.01), dollar20.2 -l); &metric_name.2="Discount Spend Per Household"; end;
if upcase(&metric_name.)='DISCOUNT UNITS' 									then do; _nw[_i] = put(_or[_i], comma22. -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='DISCOUNT UNITS PER BUYING HSHD' 	then do; _nw[_i] = put(round(_or[_i], 0.01), comma22.2 -l); &metric_name.2="Discount Units Per Buying Household"; end;
if upcase(&metric_name.)='DISCOUNT UNITS PER HSHD' 					then do; _nw[_i] = put(round(_or[_i], 0.01), comma22.2 -l); &metric_name.2="Discount Units Per Household"; end;
if upcase(&metric_name.)='EUOM' 														then do; _nw[_i] = put(round(_or[_i], 0.01), comma22.2 -l); &metric_name.2="&euom_change."; end;
if upcase(&metric_name.)='EUOM PER BUYING HSHD' 						then do; _nw[_i] = put(round(_or[_i], 0.01), comma22.2 -l);	&metric_name.2="&euom_change. Per Buying Household"; end;
if upcase(&metric_name.)='EUOM PER HSHD' 										then do; _nw[_i] = put(round(_or[_i], 0.01), comma22.2 -l);	&metric_name.2="&euom_change. Per Household"; end;
if upcase(&metric_name.)='EUOM PER UNIT' 										then do; _nw[_i] = put(round(_or[_i], 0.01), comma22.2 -l);	&metric_name.2="&euom_change. Per Unit";	end;
if upcase(&metric_name.)='EUOM PER VISIT' 									then do; _nw[_i] = put(round(_or[_i], 0.01), comma22.2 -l);	&metric_name.2="&euom_change. Per Visit"; end;
if upcase(&metric_name.)='FULL SPEND' 											then do; _nw[_i] = put(round(_or[_i], 0.01), dollar20.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='FULL SPEND PER BUYING HSHD' 			then do; _nw[_i] = put(round(_or[_i], 0.01), dollar20.2 -l); &metric_name.2="Full Spend Per Buying Household"; end;
if upcase(&metric_name.)='FULL SPEND PER HSHD' 							then do; _nw[_i] = put(round(_or[_i], 0.01), dollar20.2 -l); &metric_name.2="Full Spend Per Household"; end;
if upcase(&metric_name.)='PCT SPEND ON COUPON' 							then do; _nw[_i] = put(round(_or[_i], 0.0001), percent20.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='PCT SPEND ON DISCOUNT' 						then do; _nw[_i] = put(round(_or[_i], 0.0001), percent20.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='PCT UNITS ON COUPON' 							then do; _nw[_i] = put(round(_or[_i], 0.0001), percent20.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='PCT UNITS ON DISCOUNT' 						then do; _nw[_i] = put(round(_or[_i], 0.0001), percent20.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='PENETRATION' 											then do; _nw[_i] = put(round(_or[_i], 0.0001), percent20.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='SOR BLENDED' 											then do; _nw[_i] = put(round(_or[_i], 0.0001), percent20.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='SOR EUOM' 												then do; _nw[_i] = put(round(_or[_i], 0.0001), percent20.2 -l); &metric_name.2="Sor &euom_change."; end;
if upcase(&metric_name.)='SOR SPEND' 												then do; _nw[_i] = put(round(_or[_i], 0.0001), percent20.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='SOR UNITS' 												then do; _nw[_i] = put(round(_or[_i], 0.0001), percent20.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='SPEND' 														then do; _nw[_i] = put(round(_or[_i], 0.01), dollar20.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='SPEND PER BUYING HSHD' 						then do; _nw[_i] = put(round(_or[_i], 0.01), dollar20.2 -l); &metric_name.2="Spend Per Buying Household"; end;
if upcase(&metric_name.)='SPEND PER EUOM' 									then do; _nw[_i] = put(round(_or[_i], 0.01), dollar20.2 -l); &metric_name.2="Spend Per &euom_change."; end;
if upcase(&metric_name.)='SPEND PER HSHD' 									then do; _nw[_i] = put(round(_or[_i], 0.01), dollar20.2 -l); &metric_name.2="Spend Per Household"; end;
if upcase(&metric_name.)='SPEND PER UNIT' 									then do; _nw[_i] = put(round(_or[_i], 0.01), dollar20.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='SPEND PER VISIT' 									then do; _nw[_i] = put(round(_or[_i], 0.01), dollar20.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='TOTAL CUSTOMERS' 									then do; _nw[_i] = put(_or[_i], comma20. -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='UNITS' 														then do; _nw[_i] = put(_or[_i], comma20.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='UNITS PER BUYING HSHD' 						then do; _nw[_i] = put(round(_or[_i], 0.01), comma20.2 -l); &metric_name.2="Units Per Buying Household"; end;
if upcase(&metric_name.)='UNITS PER HSHD' 									then do; _nw[_i] = put(round(_or[_i], 0.01), comma20.2 -l); &metric_name.2="Units Per Household"; end;
if upcase(&metric_name.)='UNITS PER VISIT' 									then do; _nw[_i] = put(round(_or[_i], 0.01), comma20.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='VISITS' 													then do; _nw[_i] = put(_or[_i], comma20.2 -l); &metric_name.2=&metric_name.; end;
if upcase(&metric_name.)='VISITS PER BUYING HSHD' 					then do; _nw[_i] = put(round(_or[_i], 0.01), comma20.2 -l); &metric_name.2="Visits Per Buying Household"; end;
if upcase(&metric_name.)='VISITS PER HSHD' 									then do; _nw[_i] = put(round(_or[_i], 0.01), comma20.2 -l); &metric_name.2="Visits Per Household"; end;
end;
run;
	
%mend;

