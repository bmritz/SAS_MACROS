***********************************************************************************************************************************
***********************************************************************************************************************************
macro_name: 	make_binary_flags
author:				Brian Ritz
purpose:			transform any number of columns into a wider dataset of binary flags for every value of that column

make_binary_flags(data=, out=, var=, keep=, fmtname=, by=, fmt_legend=make_binary_flags_legend, cntlin=Y)

parameters:

data=: 					input dset that you wish to transform
out=: 					name of the output dataset you wish to create
var=:						the columns on the input dataset that you wish to transform into binary variables, separate multiple vars by spaces
keep=:					the identifying column(s) on the input dataset that you wish to keep on the output dataset to identify an observation
								if keep is omitted or left blank, all variables will be kept

prefix=:				list of names for the prefixes of the binary variables, must be in the same order as var, if left blank, defaults to var
								The names of the formats created will also match the prefixes
percent_cutoff=0:		Group valuses wih have a % of the ttal dataset < percent_cutoff into an -all_other- variable that is composed of many small non-essential values
fmt_legend=:		name of the output dataset that contains the map (or legend) of which input value each integer in the formats coorespond to
by=:						(optional) aggregate the dataset by the by paramter, taking the maximum of every binary flag for each group represented by the by parameter
cntlin=Y:				Do you want the macro to create the formats for you by calling proc format cntlin on the format legend? Defaults to Y
library=work.formats 	You may specify a library to save your formats -- default is work.formats -- which is also the sas defualt if you do not specify a library statement
dropvars=Y			Do you want to drop the original variables that were turned into binary variables? Default is Yes
missing=Y				Do you want to include missing character variables as a classification? Defaults to Yes
compress=No		Compression to use on the final dataset -- set to binary if you want to compress the final file binary 
				-- setting this option to binary will usually reduce size  of the output dataset greatly

***********************************************************************************************************************************
***********************************************************************************************************************************
;




%macro make_binary_flags(data=, out=, var=, keep=, prefix=, by=, fmt_legend=make_binary_flags_legend, library=work.formats, dropvars=Y,
percent_cutoff=0, missing=Y, compress=No, );
	* create formats is a helper function that we use to create the formats for the binary variables;
	%include "./create_formats.sas";
	* fix range fixes var calls like var_1-var_5 into var_1 var_2 var_3 ...etc;
	%if %index(&var.,-) %then %do;
	%include "./fixrange.sas";
	%fixrange(var);
	%end;
	* check if data, out, or columns is blank -- VALIDATE INPUTS;
	%if &data.=%str() %then %do;
		%put ERROR: YOU MUST SPECIFY AN INPUT DATASET WITH THE DATA= PARAMETER.;
		%abort;
	%end;

	%if &out.=%str() %then %do;
		%let out=&data.;
	%end;	

    * get a list of variable names, for use if they have a by= paramter -- check by logic below;
    proc contents data=&data. out=_invars(keep=name);
    run;

	* make a dummy format legend if we need to, because we use the format to make binary -- we will delete if we created a dummy;
	%if &fmt_legend.=%str() %then %do;
		%let fmt_leg=_dummy_fmt_legend;
	%end;
	%else %do;
		%let fmt_leg=&fmt_legend.;
	%end;

	* make a dummy format legend if we need to, because we use the format to make binary -- we will delete if we created a dummy;
	%if &keep.=%str() %then %do;
		%let keep=_all_;
	%end;

	%let _drop=;
	%if %upcase(%substr(&dropvars.,1,1))=Y %then %do;
		%let _drop = &var.;
	%end;


	* check if the number of fmtname= the number of columns or it is blank;
	%if &prefix. ne %str() %then %do;
		%if %sysfunc(countw(&prefix.)) ne %sysfunc(countw(&var.))%then %do;
			%put ERROR (make_binary_flags_macro): The number of prefixes given to the marco must be equal to the number of vars given to the macro, or else left blank;
			%abort;
		%end;
	%end;
	%else %do;
		%let prefix = &var.;
	%end;

	%if &var. ne %str() %then %do;
		%put vars are &var.;
		%put prefixes are &prefix.;
		* create all formats for the columns;
        * use a delimiter that we will (hopefully) never see in the data;
		%create_formats(data=&data., var=&var., fmtname=&prefix., fmt_legend=&fmt_leg., cntlin=Y, library=&library., missing=&missing., percent_cutoff=&percent_cutoff., replace=N, delimiter=%str(|));

		options FMTSEARCH = (&library.);

        data _to_call_execute(drop=i);  
            set &fmt_leg.;
	       format var $char5000.0;
	       do i = 1 to countw(label,"|");
        		var = catx(",",var,cat("'",scan(strip(label),i,"|"),"'"));
            end;
        run;

		%if &prefix. ne %str() %then %do;
		%let _vn=fmtname;
		%end;

		%else %do;
		%let _vn=varname;
		%end;

		data _null_;
			set _to_call_execute end = last;

			if _n_ = 1 then call execute("data &out.(drop=&_drop. compress=&compress.); set &data.(keep=&keep. &by. &var.);");

            * if else because the else code is a little speedier;
            %if &percent_cutoff. >0 %then %do;
			call execute("length "||strip(&_vn.)||"_"||strip(start)||" 3.; if "||strip(varname)||
			" in ("||strip(var)||") then "||strip(&_vn.)||"_"||strip(start)||
			"=1;else if missing("||strip(varname)||") then call missing("||strip(&_vn.)||"_"||strip(start)||"); else "||strip(&_vn.)||"_"||strip(start)||"=0;");
            %end;
            %else %do;
			call execute("length "||strip(&_vn.)||"_"||strip(start)||" 3.; if "||strip(varname)||
			"="||strip(var)||" then "||strip(&_vn.)||"_"||strip(start)||
			"=1;else if missing("||strip(varname)||") then call missing("||strip(&_vn.)||"_"||strip(start)||"); else "||strip(&_vn.)||"_"||strip(start)||"=0;");
             %end;


			if last then call execute("run;");
		run;
	
	%end;
	%else %do;
		%put NOTE (make_binary_flags_macro): No columns were specified, original dataset will be returned with keep vars.;
		data &out.;
			set &data.(keep=&keep.);
		run;
	%end;


	* WERE PRETTY MUCH DONE, but if by, then sum up;
	%if &by. ne %str() %then %do;

	* the variables we want to take the max on are all the variables we created inside this macro -- so they will be the vars in &out. and not in &data.;
		* we find those varaibles and put them into a macro variable called _newvars;

		proc contents data=&out. out=_outvars(keep=name);
		run;

		proc sort data=_invars;
			by name;
		run;

		proc sort data=_outvars;
			by name;
		run;

		data _newvars;
			merge _invars(in=a) _outvars(in=b);
			by name;
			if b and ~a then output;
		run;

		proc sql;
			select distinct(name) into : _newvars separated by " " from _newvars;
		quit;

		proc sort data=&out.;
			by &by.;
		run;

		proc means data=&out. noprint;
			by &by.;
			var &_newvars.;
			output out=&out.(drop=_:) max= / keeplen;
		run;

		* cleanup;
		proc datasets lib=work;
			delete _outvars _newvars;
		quit;

	%end;
	* this will delete the dummy format legend if it is there;
	proc datasets lib=work nolist;
	delete _dummy_fmt_legend _invars _to_call_execute;
	run;

%mend;
