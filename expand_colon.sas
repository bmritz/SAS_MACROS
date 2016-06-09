
	*** this section  gets a macro variable that is a list of all the variables that are represented by the colon;

%macro expand_colon(data=, var=, out_macro_var_name=);

	%global &out_macro_var_name.;


	* check if data, out, or columns is blank -- VALIDATE INPUTS;
	%if &out_macro_var_name.=%str() %then %do;
		%put ERROR: You must specify and output macro variable name;
		%abort;
	%end;	

	%if &var.=%str() %then %do;
		%let &out_macro_var_name. = &var.;
		%goto exit;
	%end;	

	%if &data.=%str() %then %do;
		%put ERROR: YOU MUST SPECIFY AN INPUT DATASET WITH THE DATA= PARAMETER.;
		%abort;
	%end;





	data _all_var;	
		set &data.(keep=&var. obs=1);
	run;

	proc contents data=_all_var out=_individual_vars;
	run;

	proc sql;
		select name into : &out_macro_var_name. separated by " " from _individual_vars;
	quit;

	proc datasets lib=work;
		delete _all_var _individual_vars;
	run;

	%exit:

%mend;
