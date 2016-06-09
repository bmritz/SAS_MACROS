* Brian Ritz;
* determine contributions from ancova results;


* Spend, units, visits and euom are case sensitive!;
%macro uplift_contributions(
ancova_results=,
out=,
by=customer_variable customer_cut product_variable product_cut time_variable time_cut,
variable_name=variable_name,
spend=Spend,
units=Units,
visits=Visits,
euom=Euom,
penetration=Penetration
)
;
proc format;
  value met
    1="Penetration"
    2="Visits Per Buying Household"
    3="Units Per Visit"
	4="EUOM Per Unit"
	5="Spend Per EUOM"
	6="Spend Per Unit"
	7="Total Uplift"
   ;

	 value type
	 	1="Percent"
		2="Absolute Dollar Amount (Grossed Up)"
		3="Absolute Dollar Amount (Per Household)"
		;
run;

* set up first. and last. calls in the macro;
%if &by. ne %str() %then %do;
	%let _lastby_f=first.%sysfunc(reverse(%scan(%sysfunc(reverse(&by.)),1)));
	%let _lastby_l=last.%sysfunc(reverse(%scan(%sysfunc(reverse(&by.)),1)));
%end;
%else %do;
	%let _lastby_f = _n_=1;
	%let _lastby_l = EOF;
%end;

proc sort data=&ancova_results. out=_ancova_results;
	by &by. &variable_name.;
run;

data &out.(keep=&by. _metric  contribution cont_value test_value type rename=(_metric=&variable_name.));
	length _metric $40;
	set _ancova_results end=EOF;
	by &by. &variable_name.;
	
	length cont_purchase_flag test_purchase_flag cont_spend test_spend cont_units test_units cont_visits test_visits 8.;
	array _arr {3,5} 	cont_purchase_flag cont_spend cont_units cont_visits cont_euom 
										test_purchase_flag test_spend test_units test_visits test_euom 
										sig_purchase_flag  sig_spend  sig_units  sig_visits  sig_euom;
	array _orig {3} 	CONTROL_mean TEST_mean sig_flag;
	array _out {5,7} 	customer_contrib_pct 		visits_per_cust_contrib_pct 		units_per_visit_contrib_pct 	euom_per_unit_contrib_pct		spend_per_euom_contrib_pct 		spend_per_unit_contrib_pct		total_percent_uplift 
						customer_contrib_dol 		visits_per_cust_contrib_dol 		units_per_visit_contrib_dol		euom_per_unit_contrib_dol 		spend_per_euom_contrib_dol 		spend_per_unit_contrib_dol		total_dollar_uplift
						customer_contrib_dol_hh 	visits_per_cust_contrib_dol_hh 		units_per_visit_contrib_dol_hh	euom_per_unit_contrib_dol_hh 	spend_per_euom_contrib_dol_hh 	spend_per_unit_contrib_dol_hh	total_hshd_uplift
						test_purchase_flag 			vis_per_cust_test 					units_per_visit_test			euom_per_unit_test 				spend_per_euom_test				spend_per_unit_test				total_test_dollars
						cont_purchase_flag 			vis_per_cust_cont 					units_per_visit_cont			euom_per_unit_cont  			spend_per_euom_cont				spend_per_unit_cont				total_control_dollars;

	retain _arr gross_num;
	if &_lastby_f. then do;
		do tc = 1 to 2;
			do m = 1 to 5;
				_arr[tc,m] = 0;
			end;
		end;
		gross_num=0;
	end;

	if strip(stat_test) = "Not Significant" then sig_flag = 0;
	else if strip(stat_test) = "Directional" then sig_flag = 1;
	else if strip(stat_test) = "Significant" then sig_flag = 2;

	*if you find the value of metric variable in the variable name of the variable we are currently on in our loops, then make the array variable equal to the test or control value;
	do tc = 1 to 3;
			if &variable_name.="%trim(&penetration.)" then do;
				_arr[tc,1] = _orig[tc];
				gross_num=N/2;
			end;
			if &variable_name.="%trim(&spend.)" then _arr[tc,2] = _orig[tc];
			if &variable_name.="%trim(&units.)" then _arr[tc,3] = _orig[tc];
			if &variable_name.="%trim(&visits.)" then _arr[tc,4] = _orig[tc];
			if &variable_name.="%trim(&euom.)" then _arr[tc,5] = _orig[tc];
	end;

	if &_lastby_l. then do;
		customers_test = test_purchase_flag * gross_num;
		customers_cont = cont_purchase_flag * gross_num;
		
		vis_per_cust_test = test_visits/test_purchase_flag;
		vis_per_cust_cont = cont_visits/cont_purchase_flag;

		units_per_cust_test = test_units/test_purchase_flag;
		units_per_cust_cont = cont_units/cont_purchase_flag;

		spend_per_cust_test = test_spend/test_purchase_flag;
		spend_per_cust_cont = cont_spend/cont_purchase_flag;

		euom_per_cust_test = test_euom/test_purchase_flag;
		euom_per_cust_cont = cont_euom/cont_purchase_flag;

		units_per_visit_test = units_per_cust_test / vis_per_cust_test;
		units_per_visit_cont = units_per_cust_cont / vis_per_cust_cont;


		euom_per_unit_test = euom_per_cust_test / units_per_cust_test;
		euom_per_unit_cont = euom_per_cust_cont / units_per_cust_cont; 

		spend_per_euom_test = spend_per_cust_test / euom_per_cust_test;
		spend_per_euom_cont = spend_per_cust_cont / euom_per_cust_cont;

		spend_per_unit_test = spend_per_cust_test / units_per_cust_test;
		spend_per_unit_cont = spend_per_cust_cont / units_per_cust_cont;

		spend_per_visit_test = spend_per_cust_test / vis_per_cust_test;
		spend_per_visit_cont = spend_per_cust_cont / vis_per_cust_cont;

		total_test_dollars = test_spend * gross_num;
		total_control_dollars = cont_spend * gross_num;
		
		total_dollar_uplift = total_test_dollars - total_control_dollars;
		total_percent_uplift = (total_test_dollars / total_control_dollars) - 1;

		total_hshd_uplift = test_spend - cont_spend;

		customer_contrib_pct = log(customers_test/customers_cont) / log(total_test_dollars / total_control_dollars) * (total_dollar_uplift / abs(total_dollar_uplift));
		visits_per_cust_contrib_pct = log(vis_per_cust_test/vis_per_cust_cont) / log(total_test_dollars / total_control_dollars) * (total_dollar_uplift / abs(total_dollar_uplift));
		units_per_visit_contrib_pct = log(units_per_visit_test / units_per_visit_cont) / log(total_test_dollars / total_control_dollars) * (total_dollar_uplift / abs(total_dollar_uplift));
		spend_per_unit_contrib_pct = log(spend_per_unit_test / spend_per_unit_cont) / log(total_test_dollars / total_control_dollars) * (total_dollar_uplift / abs(total_dollar_uplift));
		
		euom_per_unit_contrib_pct = log(euom_per_unit_test / euom_per_unit_cont) / log(total_test_dollars / total_control_dollars) * (total_dollar_uplift / abs(total_dollar_uplift));
		spend_per_euom_contrib_pct = log(spend_per_euom_test / spend_per_euom_cont) / log(total_test_dollars / total_control_dollars) * (total_dollar_uplift / abs(total_dollar_uplift));

		customer_contrib_dol= customer_contrib_pct * total_dollar_uplift * (total_dollar_uplift / abs(total_dollar_uplift));
		visits_per_cust_contrib_dol = visits_per_cust_contrib_pct * total_dollar_uplift * (total_dollar_uplift / abs(total_dollar_uplift));
		units_per_visit_contrib_dol = units_per_visit_contrib_pct * total_dollar_uplift * (total_dollar_uplift / abs(total_dollar_uplift));
		spend_per_unit_contrib_dol = spend_per_unit_contrib_pct * total_dollar_uplift * (total_dollar_uplift / abs(total_dollar_uplift));

		euom_per_unit_contrib_dol = euom_per_unit_contrib_pct * total_dollar_uplift * (total_dollar_uplift / abs(total_dollar_uplift));
		spend_per_euom_contrib_dol = spend_per_euom_contrib_pct *  total_dollar_uplift * (total_dollar_uplift / abs(total_dollar_uplift));

		customer_contrib_dol_hh= customer_contrib_pct * total_hshd_uplift * (total_hshd_uplift / abs(total_hshd_uplift));
		visits_per_cust_contrib_dol_hh = visits_per_cust_contrib_pct * total_hshd_uplift * (total_hshd_uplift / abs(total_hshd_uplift));
		units_per_visit_contrib_dol_hh = units_per_visit_contrib_pct * total_hshd_uplift * (total_hshd_uplift / abs(total_hshd_uplift));
		spend_per_unit_contrib_dol_hh = spend_per_unit_contrib_pct * total_hshd_uplift * (total_hshd_uplift / abs(total_hshd_uplift));

		euom_per_unit_contrib_dol_hh = euom_per_unit_contrib_pct * total_hshd_uplift * (total_hshd_uplift / abs(total_hshd_uplift));
		spend_per_euom_contrib_dol_hh = spend_per_euom_contrib_pct *  total_hshd_uplift * (total_hshd_uplift / abs(total_hshd_uplift));

		do i = 1 to 3;
			do j = 1 to 7;
			
			if j < 7 then cont_value=_out[5,j]; else cont_value=.;
			if j < 7 then test_value=_out[4,j]; else test_value=.;
			_metric = put(j, met.);
			type=put(i, type.);
			contribution=_out[i,j];
			if contribution ne . then output;
			end;
		end;
	end;
run;

proc datasets lib= work;
	delete _ancova_results;
run;
%mend;
