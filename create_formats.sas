***********************************************************************************************************************************
***********************************************************************************************************************************
macro_name: 	create_formats
author:				Brian Ritz
purpose:			create formats from variables in a dataset

macro create_formats(data=, var=, fmtname=, fmt_legend=create_formats_legend, cntlin=Y)  -makes the format from 1,2,3,4 to the values of the variables
used as a helper in make_binary_vars

NOTE: all variable names for the create formats must be 29 characters or less

parameters:

data: 								input dset that you wish to create formats from
out: 									name of the output dataset you wish to create -- will only be created if replace=Y
var:									the columns on the input dataset that you wish to create formats from
fmtname:							list of names for the formats created for the binary variables, must be in the same order as var, if left blank, defaults to var
fmt_legend:						name of the output dataset that contains the map (or legend) of which input value each integer in the formats coorespond to
cntlin=Y:							Do you want the macro to create the formats for you by calling proc format cntlin on the format legend? Defaults to Y
library=work.formats 	You may specify a library to save your formats -- default is work.formats -- which is also the sas defualt if you do not specify a library statement
missing=Y							Include missing variables on the format?
replace=N							Should the variables be replaced with a numeric that is represented by the format?
startnum=1						This is the number which will be assigned to the first <start> number in the format -- usually set to 0 or 1
													for example, 	if startnum=1 then sex F will be represented by 1 and sex M will be represented by 2
																				if startnum=0 then sex F will be represented by 0 and sex M will be represented by 1
fmt_final_number_suffix			This is the suffix that will be concatinated to the format name if the format name ends in a non-alphabetic character(which is illegal for format names);
***********************************************************************************************************************************
***********************************************************************************************************************************
;

%macro create_formats(data=, out=, var=, fmtname=, fmt_legend=create_formats_legend, cntlin=Y, library=work.formats, missing=Y, replace=N, percent_cutoff=0, startnum=1,
fmt_final_number_suffix=f, delimiter=%str(,));

	* check if data, out, or columns is blank -- VALIDATE INPUTS;
	%if &data.=%str() %then %do;
		%put ERROR: YOU MUST SPECIFY AN INPUT DATASET WITH THE DATA= PARAMETER.;
		%abort;
	%end;

	%if &out.=%str() %then %do;
		%let out=&data.;
	%end;	


	*** this section is so that colons will work in the macro;
	%if %index(&var.,:) %then %do;
		data _all_var;	
			set &data.(keep=&var.);
		run;

		proc contents data=_all_var out=_individual_vars;
		run;

		proc sql;
			select name into : var separated by " " from _individual_vars;
		quit;

		proc datasets lib=work;
			delete _all_var _individual_vars;
		run;
	%end;


	* initialize foward rename to blank, we will append on to this if there is a fmtname parameter;
	%let _forward_rename=;
	%let _reverse_rename=;
	* check if the number of fmtname= the number of var= or it is blank -- if its there append on the forward rename;
	%if &fmtname. ne %str() %then %do;
		%if %sysfunc(countw(&fmtname.)) ne %sysfunc(countw(&var.))%then %do;
			%put ERROR (create_formats_macro): The number of fmtnames given to the marco must be equal to the number of var given to the macro, or else left blank;
			%abort;
		%end;
		%else %do i = 1 %to %sysfunc(countw(&fmtname.));
			%let _forward_rename=&_forward_rename. %scan(&var.,&i.) = %scan(&fmtname.,&i.)%str(;);
			%let _reverse_rename=&_reverse_rename. %scan(&fmtname.,&i.) = %scan(&var.,&i.)%str(;);
		%end;
	%end;
	%else %do;
		%let fmtname = &var.;
		%let _forward_rename=;
		%let _reverse_rename=;
	%end;

	data _int;
		set &data;
		&_reverse_rename.;
		%do i = 1 %to %sysfunc(countw(&fmtname.));
		%scan(&fmtname.,&i.) = strip(%scan(&fmtname.,&i.));
		%end;
	run;

	%let _missing=;
	%if %upcase(%substr(&missing.,1,1))=Y %then %let _missing= missing;

	* use the forward rename to use the format name instead of the variable name for hte format name;
	proc freq data=_int;
		tables &fmtname. / &_missing.;
		ods output OneWayFreqs=_freqs;
	run;
	ods output close;

	* this gets the blanks on the bottom change them to ~ (which is the last sort character);
	* we need them at the bottom because we look at the lag function to know when it is really missing or when it is missing because we are not on that F_ variable 
	* (check the last part of the datastep);
	data _freqs(drop=i);
		set _freqs;
		array _bl {*} F_:;
		do i = 1 to dim(_bl);
		if strip(_bl[i]) = "" then _bl[i] = "~~~";
		end;
	run;

	* change the lengths for the f_ variables because we may make more percents;
	%if &percent_cutoff. > 0 %then %do;

	proc contents data=_freqs out=_freqs_vars;
	run;

	proc sql;
	select name into :_freq_fs separated by " " from _freqs_vars where upcase(substr(name, 1,2)) = "F_";
	quit;

	proc sort data=_freqs;
		by table;
	run;


	data _freqs/*(drop= our_var i less_than less_than_pct)*/;
		length &_freq_fs. $1000;
		set _freqs;
		by table;
		length less_than $1000; length less_than_pct 8.;
		retain our_var less_than less_than_pct;
		array _var {*} F_:;
		if first.table then do; 
			less_than=""; 
			less_than_pct = 0; 
			our_var=.;
		end;
		if percent < &percent_cutoff. then do ;
			do i = 1 to dim(_var);
				if strip(compress(_var[i],"~")) ne "" then do;
					less_than = catx("&delimiter.", less_than, _var[i]);
					less_than_pct = sum(less_than_pct, percent);
					* caputre which i it is so we can add on an all other category in the last.table section;
					our_var = i;
				end;
			end;
		end;
		else output;

		if last.table then do;
			do i = 1 to dim(_var);
				if i = our_var then do;
					_var[i] = less_than;
					percent=less_than_pct;
				end;
			end;
			xxx = 1;
			if less_than_pct > 0 then output;
		end;
	run;

	proc datasets lib=work;
		delete _freqs_vars;
	run;
	%end;

	proc sort data=_freqs;
	   by table F_:;
	run;

	* create the format dataset;
	data &fmt_legend.(keep=start label type fmtname varname percent frequency);
		length start 8;
		length label $1000;
		length type $1 fmtname $31;
		retain start;
		length varname $32;
		set _freqs end=eof;

		* forward rename sets up the variables for the macro language at the end here;
		&_forward_rename.;

		array _var {*} F_:;
		by table F_:;

		type='N';

		fmtname=strip(tranwrd(table, "Table ", ""));


		%do i = 1 %to %sysfunc(countw(&fmtname.));
		if upcase("%scan(&fmtname.,&i.)") = upcase(fmtname) then do;
			varname = "%scan(&var.,&i.)";
		end;
		%end;

		if table ne lag(table) then do;
			start=&startnum.-1;
		end;

		do i = 1 to dim(_var);
			if strip(compress(_var[i],"~")) eq "" then _var[i]="";
			label = catx("", label, strip(_var[i]));
		end;

		start = sum(start,1);
		* make sure the format name ends in a letter;
		if anyalpha(substr(reverse(strip(fmtname)),1,1)) = 0 then fmtname = catt(fmtname,"&fmt_final_number_suffix.");
		output;
	run;

	proc sort data=&fmt_legend.;
		by varname start;
	run;

	proc datasets lib=work nolist;
		delete _int _freqs;
	run;

	* cntlin the format;
	%if %upcase(%substr(&cntlin.,1,1))=Y %then %do;
		proc format library = &library. cntlin = &fmt_legend.;
		run;
	%end;

	%if %upcase(%substr(&replace.,1,1))=Y %then %do;
		
		* reverse the format -- make informats to change the chars to numbers;
		data _null_;
			set &fmt_legend. end=eof;
			by varname;
			if first.varname then call execute("proc format library=&library.;invalue _"||strip(varname)||"f ");
			* NOTE: can remove this strip() in order to use different formats for leading or trailing spaces;
			if ~missing(label) then call execute('"'||strip(label)||'"='||start||" ");
			if missing(label) then call execute("' '="||start||" ");
			if last.varname then call execute("; run;");
		run;

		data &out.(compress=yes drop=&var. rename=(%do i = 1 %to %sysfunc(countw(&var.)); %scan(&var.,&i.)X = %scan(&var.,&i.) %end;));
			set &data.;
			%do i = 1 %to %sysfunc(countw(&var.));
				length %scan(&var.,&i.)X 3.;
				if ~missing(%scan(&var.,&i.)) then do;
					%scan(&var.,&i.)X = input(strip(%scan(&var.,&i.)), _%scan(&var.,&i.)f.);
				end;
				else do;
					%scan(&var.,&i.)X = input(' ', _%scan(&var.,&i.)f.);
				end;
			%end;
		run;
	%end;


%mend;
