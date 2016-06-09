
%macro missing_distributions(data=, out=, var=);

* pre process so we know number of variables;

%if &var. = %str() %then %do;
proc contents data=&data. out=_varnames;
run;

proc sql;
	select put(count(distinct name),3.-l) into : _num_num_vars from _varnames where type=1;
	select strip(name) into : _all_num_vars separated by " " from _varnames where type=1;
quit;

proc datasets lib=work;
delete _varnames;
run;
%end;
%else %do;
	%let _num_num_vars = %sysfunc(countw(&var.));
	%let _all_num_vars = &var.;
%end;
* pre screen first x obs for speed -- dont need to loop through a lot of variables if within the first x obs we know they are character;
data &out.(keep=variable_name pct_obs_zero pct_obs_missing obs_zero obs_missing);
	set &data. end=EOF;
	length numeric_vars $9600 total_obs 8.;
	array _num{&_num_num_vars.} &_all_num_vars.;
	array _flag{2,&_num_num_vars.} 8. _num_1-_num_&_num_num_vars. _nums_1-_nums_&_num_num_vars.;
	retain _flag numeric_vars total_obs;

	* assume every character variable is a numeric var until we see it isnt;
	if _n_ = 1 then do i = 1 to dim(_num);
	_flag[1,i]=0; _flag[2,i]=0;
	end;

	if _n_ = 1 then total_obs=0;
	total_obs=sum(total_obs,1);

	do i = 1 to dim(_num);

		if missing(_num[i]) then _flag[1,i]=sum(_flag[1,i],1);/*and _num[i] not eq 0*/;
		if _num[i] = 0 then _flag[2,i] = sum(_flag[2,i], 1);
/*		if is_notthere then do;*/
/*			if _num[i] not eq 0 then*/
/*			*/
/*		end;*/
	end;

	if EOF then do i = 1 to dim(_num) ;
		variable_name = vname(_num[i]);
		obs_zero = _flag[2,i];
		obs_missing = _flag[1,i];
		pct_obs_zero = _flag[2,i] / total_obs;
		pct_obs_missing = _flag[1,i] / total_obs;
		output;
	end;
run;

%mend;
/**/
/*data testin;*/
/*	set sashelp.class;*/
/*	if _n_ in (4,6) then height =.;*/
/*	if _n_ = 9 then weight = .;*/
/*run;*/
/*%missing_distributions(data=testin, out=test, var= height weight);*/
