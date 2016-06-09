***********************************************************************************************************************************
***********************************************************************************************************************************
macro_name: 	remove_outliers
author:				Brian Ritz
purpose:			remove outliers from a long dataset of transactions summary

make_binary_flags(data=, 
out=, 
percentile=99.9,
variables=spend units visits euom,
by= product_group time_group variable_name,
variable_name_var=variable_name,
value_var=value,
hshd_var=hshd_id,
outliers_out=remove_outliers_macro_outliers)

parameters:

data=: 					input dset that you wish to transform
out=: 					name of the output dataset you wish to create that will have the outliers removed
percentile=99.9:		the percentile cutoff, over which a household will be considered an outlier and thrown out of the analysis,
								default is 99.9
variables=:			the variable names under the column specified by the variable_name_var parameter that you wish to find outliers for
by=:						the by variables that you wish to subset your search for outliers by -- typically a column for product_group and a column for time_group and a column for variable_name
variable_name_var=:	the name of the variable on the input dataset that represents the name of the metric you are looking for outliers on -- if you got the summary dataset from the dh_transactions_summary macro
										then this parameter should be variable_name
										variable_name is the defaul

value_var=:			the name of the variable that contains the values of the long dataset -- typically called value 
								default is value because that is the name of the value var coming out of the dh_transactions_summary macro
hshd_var=:			the name of the variable on the input dataset containing an identifier for the household
outliers_out=remove_outliers_macro_outliers:	The name of the output dataset that contains all records from the input dataset that were thrown out because they were outliers

TIME: depending on the size of the input dataset -- this should take 2-3 times as long as it would take to sort your input dataset by the by variables.
***********************************************************************************************************************************
***********************************************************************************************************************************
;


%macro remove_outliers(
data=,
out=,
percentile=99.9,
variables=spend units visits euom,
by= product_group time_group variable_name,
variable_name_var=variable_name,
value_var=value,
hshd_var=hshd_id,
outliers_out=remove_outliers_macro_outliers
);

* check if data, out, or columns is blank -- VALIDATE INPUTS;

%if &data.=%str() %then %do;
	%put ERROR: YOU MUST SPECIFY AN INPUT DATASET WITH THE DATA= PARAMETER.;
	%abort;
%end;

%if &out.=%str() %then %do;
	%put ERROR: YOU MUST SPECIFY AN OUTPUT DATASET WITH THE OUT= PARAMETER.;
	%abort;
%end;	

%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/format_macro_vars.sas";
proc sort data=&data. out=_trans_smry;
	by &by. &value_var.;
run;

proc rank data=_trans_smry out=_ranks percent;
	var &value_var.;
	by &by.;
	ranks percentile;
run;

%let variables=%upcase(&variables.);
%single_quote(variables, ",");

data &outliers_out.;
	set _ranks;
	if upcase(&variable_name_var.) in (&variables.) and percentile > &percentile. then output;
run;

proc datasets lib=work;
	delete _ranks;
run;

proc sort data=&outliers_out. nodupkey out=_outlier_hshds(keep=&hshd_var.);
	by &hshd_var.;
run;

proc sql;
select count(distinct &hshd_var.) into :_num_outliers from _outlier_hshds;
quit;

%put NOTE (remove_outliers_macro): There were &_num_outliers. households thrown out of the dataset because they were outliers.;

* for the hash join, we need a length statement if the hshd_var is a character;

proc contents data=_outlier_hshds out=_vars;
run;

data _null_;
	set _vars;
	if type = 2 then _a = cats("$", length);
	else _a = cats(length, ".");
	if name = upcase("&hshd_var.") then do;
		call symput("_length_stmt", cat("length ", name, " ", _a));
	end;
run;
%put &_length_stmt.;
* anti join;
data &out.;
	&_length_stmt. ;
  if _N_=1 then do;                                  
    declare hash outl(dataset: "_outlier_hshds"); 
    outl.definekey("&hshd_var.");                   
    outl.definedone();                               
    end;                                             
  set _trans_smry;
  if outl.check() ne 0;      *** only output observations where the hshd_var is NOT on _outlier_hshds***;
run;

proc datasets lib=work;
	delete _outlier_hshds _trans_smry _vars;
run;

%mend;
