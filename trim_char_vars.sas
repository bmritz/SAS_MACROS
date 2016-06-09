
***********************************************************************************************************************************
***********************************************************************************************************************************
macro_name: 	trim_char_vars
author:				Brian Ritz
purpose:			make the lengths of all character variables in a dataset as small as possible in order to save space

PARAMETERS

data= 													input dataset name --this has a variable that represents dib_cust_id on it
out=														output dataset name -- defaults to original dataset name if left blank or omitted

***********************************************************************************************************************************
***********************************************************************************************************************************
;



 %macro _helptrim(num);
 %global var type len;
 %let dsid=%sysfunc(open(&data,i));
 %let var=%sysfunc(varname(&dsid,&num));
 %let type=%sysfunc(vartype(&dsid,&num));
 %let len=%sysfunc(varlen(&dsid,&num));
 %let rc=%sysfunc(close(&dsid));
 %mend _helptrim;

%macro trim_char_vars(data=,out=);

	%if &out=%str() %then %do;
		%let _output_dset=&data.;
	%end;
	%else %do;
		%let _output_dset=&out.;
	%end;

	%let dsid=%sysfunc(open(&data,i));
	%let nvars=%sysfunc(attrn(&dsid,nvars));
	%let nobs=%sysfunc(attrn(&dsid,nobs));
	%let label=%sysfunc(attrc(&dsid,label));
	%let rc=%sysfunc(close(&dsid));

	%if &nobs>0 %then %do;

	data _null_(compress=Y);
		set &data end=last;
		retain _1-_&nvars 1;
		length _all $10000; 
		length _char $10000;
		%do i=1 %to &nvars;
			%_helptrim(&i);
			%if &type=C %then _&i=max(_&i,length(&var));
			%else if _n_=1 then _&i=&len;
			;
		%end;

		if last then
			do;
				%do i=1 %to &nvars;
				%_helptrim(&i);
/*				%if &type=C %then _char=cat(strip(_char)," &var ","$", strip(put(_&i,best.)),".");*/
				_all=cat(strip(_all)," &var ",
				%if &type=C %then '$',;
				strip(put(_&i,best.)));
				%end;

				call execute("data &_output_dset.(&label); length "||strip(_all)||
				"; set &data.; run;");
				drop _: ;

			end;
 run;
 %end;
 %else %do;
	 data &_output_dset.(&label);
	 set &data.;
	 run;
 %end;
 
%mend trim_char_vars;
