* macro name possibilties;
* find distributions of each variable named in the var parameter;


%macro possibilities(data=, var=, missing=Y, out=);

%include "./create_formats.sas";

%create_formats(data=&data., var=&var., cntlin=N, replace=N, fmt_legend=_possibilities, missing=&missing.);

data &out.(rename=(label=character_value) drop=start type fmtname);
  length numeric_value 8.;
  set _possibilities;
  numeric_value = label * 1;
run;

proc datasets lib=work;
  delete _possibilities;
run;

%mend;


