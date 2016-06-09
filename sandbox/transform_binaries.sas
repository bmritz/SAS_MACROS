
%macro transform_binaries(data=,dep_var=,binary_vars=,out=);

%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/data_vars_to_macro_vars.sas";

data _binaries (drop=&binary_vars. i);
set &data. (keep= &dep_var. &binary_vars.);
length independent_variable $32;
length value $7;
array _bis{*} &binary_vars.;

do i=1 to dim(_bis);

	independent_variable=vname(_bis[i]);
	if _bis[i]=0 then value="zero";
	else if _bis[i] =1 then value="one";
	else if missing(_bis[i]) then value="missing";
    output;
end;

run;

proc sort data=_binaries; by independent_variable; run;

proc means data=_binaries noprint nway;
	by independent_variable;
	var &dep_var.;
	class value;
	output out=_binary_means mean=;
run;

proc transpose data=_binary_means out=_means;
	by independent_variable;
	var &dep_var.;
	id value;
run;

data &out.(keep= independent_variable imputed_value);
set _means;
one_diff = abs(one-missing);
zero_diff = abs(zero-missing);

imputed_value = one_diff < zero_diff;

run;

%mend transform_binaries;
