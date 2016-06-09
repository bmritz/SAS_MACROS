** macro name: apply_formats;
** Brian Ritz;
** automatically applies the formats specified by fmt_legend to the dataset specified in data= by looking up the variable name;
** separate format datasets in fmt_legend with spaces -- the datasets should be the ones that come out of create_formats macro;

%macro apply_formats(data=, fmt_legend=, out=%str());

%if &out.=%str() %then %do;
%let out=&data.;
%end;

* append all formats if there are multiple;
data _all_fmts;
	set &fmt_legend.;
run;

* load in format;
proc format cntlin=_all_fmts;
run;

* find the overlap in variables;

proc contents data=&data out=_vars;
run;

data _vars;
	set _vars;
	name=upcase(name);
run;

proc sort data=_vars;
	by name;
run;

data _leg;
	set _all_fmts;
	varname=upcase(varname);
run;

proc sort data=_leg;
	by varname;
run;

data _vars_to_fmt;
	merge _vars(keep=name rename=(name=varname) in=a) _leg(in=b);
	by varname;
	if a and b then output;
run;


proc sql;
	select distinct varname into : _vars_to_fmt separated by " " from _vars_to_fmt;
run;
%let _num_vars_to_fmt=%sysfunc(countw(&_vars_to_fmt.));
proc sort data=_vars_to_fmt nodupkey;
	by varname fmtname;
run;

%let _rename_stmt = %str(rename=%();
%do i = 1 %to %sysfunc(countw(&_vars_to_fmt.));
	%let _rename_stmt = %str(&_rename_stmt.) _xx_&i.=%scan(&_vars_to_fmt., &i.);
%end;
%let _rename_stmt=&_rename_stmt. %str(%));

data _null_;
	set _vars_to_fmt end=EOF;
	if _n_ = 1 then call execute("data &out.(drop=&_vars_to_fmt. &_rename_stmt. ); set &data.;");
	call execute ("_xx_"||strip(_n_)||"=put("||strip(varname)||","||strip(fmtname)||".);");
	if EOF then call execute("run;");
run;

proc datasets lib=work;
	delete _vars _leg _vars_to_fmt _all_fmts;
run;

%mend;
