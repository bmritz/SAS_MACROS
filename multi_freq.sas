* macro name: multi_freq
* brian ritz;
* purpose: to run the frequency tables for multiple variables in a single dataset separately, and then stack them on top of eachother long;
* parameters:

data - input dataset
by - by variable inputs into the proc freq
var - variables for which you want frequencies -- these will go into the tables statement in the proc freq
out - output dataset
id_var - name of the variable on the output dataset which will specify the variable name on the input dataset for which that output observation represents
include_missing - if this variable is Y, then the missing values are included in the proc freq, anything else, and missing values are not counted;

%macro multi_freq(data=, by=, var=, out=, id_var=variable, include_missing=Y);

	%include "./data_vars_to_macro_vars.sas";
	%data_vars_to_macro_vars(data=&data., var=&var., numeric_name=_nvar);

	%if &by. ne %str() %then %do;
	proc sort data=&data. out=_d;
		by &by.;
	run;
	proc freq data=_d noprint;
	%end;
	%else %do;
	proc freq data=&data. noprint;
	%end;

	%if &by. ne %str() %then %do;	by &by.; %end;
		%do i = 1 %to %sysfunc(countw(&_nvar.));
		%let _v = %scan(&_nvar.,&i.);
			tables &_v. / out=_out&i. %if %upcase(&include_missing.)=Y %then %do; missing %end; ;
		%end;
	run;

	data &out.(drop=valname_:);
		length value $100;
		set 
			%do i = 1 %to %sysfunc(countw(&_nvar.));
			%let _v = %scan(&_nvar.,&i.);
			_out&i.(rename=(&_v.=valname_&i.) in=a&i.)
			%end;
		;

		length &id_var. $32;
		%do i = 1 %to %sysfunc(countw(&_nvar.));
		%let _v = %scan(&_nvar.,&i.);
		if a&i. then do;
			&id_var.="&_v.";

			%if %getType(&data.,&_v.)=C %then %do;
			value=valname_&i.;
			%end;
			%else %do;
			value = put(valname_&i., best32.-l);
			%end;
		end;
		%end;
	run;

	proc datasets lib=work;
		delete _d _out1-_out%sysfunc(countw(&_nvar.));
	run;
%mend;
