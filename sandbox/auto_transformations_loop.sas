
/*%let data=sashelp.class;*/
/**/
/*data to_test;*/
/*	set sashelp.class;*/
/*	if _n_ = 3 or _n_ = 7 or _n_ = 13then weight = .;*/
/*  if _n_ = 7 or _n_ = 8 or _n_ = 3 then age= .;*/
/*  if _n_ = 7 or _n_ = 10  or _n_ = 11 or _n_ =12then height=.;*/
/*  if mod(_n_,2) = 0 then bin = 1;*/
/*  else bin = 0;*/
/*  if mod(_n_, 5) = 0 then bin =.;*/
/**/
/*run;*/
/**/
/*%let data=to_test;*/
/**/
/*%let dep_var = age;*/
/*%let indep_var = weight height bin;*/
/*%let i =1;*/
/** try all transformations;*/
/*%let id= name;*/
/*%let longout=test123;*/

* TODO: MAKE COMPATABLE WITH > 1 DEPENDENT VARS;
/*%let data=all_model_data2; %let id=consumer_guid; %let dep_var=pgroup_1; %let indep_var=&independent_variables.; %let longout=longout;%let wideout=wideout;*/
* this has percent suffix;

%macro auto_transformations_bin(data=, id=, dep_var=, _bin_vars=, longout=longout, wideout=wideout);
%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/data_vars_to_macro_vars.sas";
%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/list_macros.sas";
/** id is a unique identifier for each row;*/
/**/
/**find binary_vars-- this makes a macro variable called bin_vars ;*/
/*%data_vars_to_macro_vars(data=&data., var=&indep_var., binary_name=_bin_vars, non_binary_numeric_name=_nonbin_vars);*/
/*%put &_nonbin_vars.;*/

%let _nonbin_vars = %trim(&_nonbin_vars.);
/*%let _bin_vars = %trim(&_bin_vars.);*/
*make all transformations -- we will pick best later;
data _to_reg(keep= &id. &dep_var. sqrt log inv lin /*bc:*/ _binary_flag independent_variable)
      _missing_means(keep=independent_variable mean _binary_flag);
  set &data. end=eof;
  length independent_variable $32;
  length _binary_flag 3.;

  * non - binary variables;
/*  array _ind {*} &_nonbin_vars.;*/
/*  array _rt {*} %suffix(_m, &_nonbin_vars.);  *running total of dep var for when it is missing;*/
/*  array _num {*} %suffix(_n, &_nonbin_vars.);*/

  * binary variables;
	array _ind_b {*} &_bin_vars.;
  * multidimensinal array will calcualte the mean for 0s and mean for 1s;
  array _rt_b {*} %suffix(_m, &_bin_vars.);                                                               *running total of dep var for when it is missing;
  array _M_b {0:3, %sysfunc(countw(&_bin_vars.))} %suffix(_0, &_bin_vars.) %suffix(_1, &_bin_vars.) %suffix(_0n, &_bin_vars.) %suffix(_1n, &_bin_vars.);        *running total of dep var for when it is not missing;
  array _num_b {*} %suffix(_n, &_bin_vars.);


  retain _rt _num _rt_b _M_b _num_b;
  sqrt=.; log=.; inv=.; lin=.;

  * binary variables;
  do i = 1 to dim(_ind_b);
	independent_variable = vname(_ind_b[i]);
    lin = _ind_b[i];
    if ~missing(_ind_b[i]) then do;
      _M_b[_ind_b[i], i] = sum(_M_b[_ind_b[i], i], &dep_var.);
      _M_b[_ind_b[i]+2, i] = sum(_M_b[_ind_b[i]+2, i], 1);
    end;
    else do;  
      _rt_b[i] = sum(_rt_b[i], &dep_var.);
      if ~ missing(&dep_var.) then _num_b[i] = sum(_num_b[i], 1);
    end;
    _binary_flag=1;
	if ~missing(&dep_var.) and ~missing(_ind_b[i]) then    
		output _to_reg;

  end;

  * non-binary variables;
/*	do i = 1 to dim(_ind);*/
/*  */
/*    * other transforms;*/
/*		sqrt = sqrt(_ind[i]);								*/
/*		log = log(_ind[i]+0.1);*/
/*		inv = (1/(_ind[i]+0.1));*/
/*		lin = _ind[i];*/
/**/
/*		independent_variable = vname(_ind[i]);*/
/**/
/*    * tally up the sum of the dependent variables when the independent variable is missing */
/*    (so we can get the mean);*/
/*    if missing(_ind[i]) then do;  */
/*      _rt[i] = sum(_rt[i], &dep_var.);*/
/*      if ~ missing(&dep_var.) then _num[i] = sum(_num[i], 1);*/
/*    end;*/
/*    _binary_flag=0;*/
/*	if ~missing(&dep_var.) and ~missing(_ind[i]) then*/
/*		output _to_reg;*/
/*	end;*/
/*	if eof then call symputx("_missing_mean", missing_tot/missing_n);*/
*non -binary vars;
/*  if eof then do i = 1 to dim(_num);*/
/*    independent_variable = vname(_ind[i]);*/
/*    if _num[i] > 0 then mean = _rt[i]/_num[i];*/
/*    else mean = 0;*/
/*    output _missing_means;*/
/*  end;*/
*binary vars;
  if eof then do i = 1 to dim(_num_b);
    independent_variable = vname(_ind_b[i]);
    if _num_b[i] > 0 then mean = _rt_b[i]/_num_b[i];
    else mean = 0;
    zero_mean = _M_b[0,i] / _M_b[2,i];
    one_mean = _M_b[1,i] / _M_b[3,i];
    if abs(one_mean-mean) - abs(zero_mean-mean) > 0 then mean=0;
    else mean=1;
    output _missing_means;
  end;
run;

proc sort data=_missing_means;
  by independent_variable;
run;

proc sort data=_to_reg;
	by independent_variable;
run;

* find the best model in terms of rsquare (correlation) and then output its coefficients;
proc reg data=_to_reg(where=(_binary_flag=0)) outest=_model_est corr edf noprint;
	by independent_variable;
	model &dep_var. = sqrt log inv lin /*bc:*/ / selection = RSQUARE BEST=1 stop=1;
run;



* use the datasets to create macro variables that can be called directly on the input dataset;
data dset_to_call_execute;
	merge _model_est(in=a) _missing_means(in=b);
	by independent_variable;
run;

data transforms_selected;
set dset_to_call_execute end=EOF;
array _est {4} sqrt log inv lin;
if _n_ = 1 then call execute("data &wideout.(keep=&id. &dep_var. &_nonbin_vars. &_bin_vars.); set &data.;");

if _binary_flag = 0 then do i = 1 to dim(_est);
  if not missing(_est[i]) then do;
	* missing;
	call execute("if missing("||independent_variable||") then "||independent_variable||"=(coalesce(&dep_var.,"||mean||")-"||intercept||")/"||_est[i]||";");

	* transformations;
  	* dont look for lin because if it is lin then there is no transformation;
  	if strip(vname(_est[i])) = "sqrt" then call execute("if "||independent_variable||"<0 then "||independent_variable||" = 0;"||independent_variable||"=sqrt("||independent_variable||");");
	if strip(vname(_est[i])) = "log" then call execute("if "||independent_variable||"<0 then "||independent_variable||" = 0;"||independent_variable||"=log("||independent_variable||"+0.1);");
  	if strip(vname(_est[i])) = "inv" then call execute(independent_variable||"=(1/("||independent_variable||"+0.1));");
	
	transformation=vname(_est[i]);
	* excape loop;
	i = dim(_est);
  end;
end;
else do;
	call execute(independent_variable||"=coalesce("||independent_variable||","||mean||");");
end;
if EOF then call execute("run;");
run;



%mend;
%macro auto_transformations_nonbin(data=, id=, dep_var=, _nonbin_vars=, longout=longout, wideout=wideout);
%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/data_vars_to_macro_vars.sas";
%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/list_macros.sas";
/** id is a unique identifier for each row;*/
/**/
/**find binary_vars-- this makes a macro variable called bin_vars ;*/
/*%data_vars_to_macro_vars(data=&data., var=&indep_var., binary_name=_bin_vars, non_binary_numeric_name=_nonbin_vars);*/
/*%put &_nonbin_vars.;*/

%let _nonbin_vars = %trim(&_nonbin_vars.);
/*%let _bin_vars = %trim(&_bin_vars.);*/
*make all transformations -- we will pick best later;
data _to_reg(keep= &id. &dep_var. sqrt log inv lin /*bc:*/ _binary_flag independent_variable)
      _missing_means(keep=independent_variable mean _binary_flag);
  set &data. end=eof;
  length independent_variable $32;
  length _binary_flag 3.;

  * non - binary variables;
  array _ind {*} &_nonbin_vars.;
  array _rt {*} %suffix(_m, &_nonbin_vars.);  *running total of dep var for when it is missing;
  array _num {*} %suffix(_n, &_nonbin_vars.);

  * binary variables;
/*	array _ind_b {*} &_bin_vars.;*/
/*  * multidimensinal array will calcualte the mean for 0s and mean for 1s;*/
/*  array _rt_b {*} %suffix(_m, &_bin_vars.);                                                               *running total of dep var for when it is missing;*/
/*  array _M_b {0:3, %sysfunc(countw(&_bin_vars.))} %suffix(_0, &_bin_vars.) %suffix(_1, &_bin_vars.) %suffix(_0n, &_bin_vars.) %suffix(_1n, &_bin_vars.);        *running total of dep var for when it is not missing;*/
/*  array _num_b {*} %suffix(_n, &_bin_vars.);*/

  * box cox transforms;
/*  array _bc {-1:5} bc_1-bc_7;*/

  retain _rt _num _rt_b _M_b _num_b;
/*  do i = -1 to 5 ;*/
/*    _bc[i] = .;*/
/*  end;*/
  sqrt=.; log=.; inv=.; lin=.;

  * binary variables;
/*  do i = 1 to dim(_ind_b);*/
/*	independent_variable = vname(_ind_b[i]);*/
/*    lin = _ind_b[i];*/
/*    if ~missing(_ind_b[i]) then do;*/
/*      _M_b[_ind_b[i], i] = sum(_M_b[_ind_b[i], i], &dep_var.);*/
/*      _M_b[_ind_b[i]+2, i] = sum(_M_b[_ind_b[i]+2, i], 1);*/
/*    end;*/
/*    else do;  */
/*      _rt_b[i] = sum(_rt_b[i], &dep_var.);*/
/*      if ~ missing(&dep_var.) then _num_b[i] = sum(_num_b[i], 1);*/
/*    end;*/
/*    _binary_flag=1;*/
/*	if ~missing(&dep_var.) and ~missing(_ind_b[i]) then    */
/*		output _to_reg;*/
/**/
/*  end;*/

  * non-binary variables;
	do i = 1 to dim(_ind);
  
    * box cox transform;
    * other transforms;
		sqrt = sqrt(_ind[i]);								
		log = log(_ind[i]+0.1);
		inv = (1/(_ind[i]+0.1));
		lin = _ind[i];

		independent_variable = vname(_ind[i]);

    * tally up the sum of the dependent variables when the independent variable is missing 
    (so we can get the mean);
    if missing(_ind[i]) then do;  
      _rt[i] = sum(_rt[i], &dep_var.);
      if ~ missing(&dep_var.) then _num[i] = sum(_num[i], 1);
    end;
    _binary_flag=0;
	if ~missing(&dep_var.) and ~missing(_ind[i]) then
		output _to_reg;
	end;
*non -binary vars;
  if eof then do i = 1 to dim(_num);
    independent_variable = vname(_ind[i]);
    if _num[i] > 0 then mean = _rt[i]/_num[i];
    else mean = 0;
    output _missing_means;
  end;
*binary vars;
/*  if eof then do i = 1 to dim(_num_b);*/
/*    independent_variable = vname(_ind_b[i]);*/
/*    if _num_b[i] > 0 then mean = _rt_b[i]/_num_b[i];*/
/*    else mean = 0;*/
/*    zero_mean = _M_b[0,i] / _M_b[2,i];*/
/*    one_mean = _M_b[1,i] / _M_b[3,i];*/
/*    if abs(one_mean-mean) - abs(zero_mean-mean) > 0 then mean=0;*/
/*    else mean=1;*/
/*    output _missing_means;*/
/*  end;*/
run;
proc sort data=_missing_means;
  by independent_variable;
run;

proc sort data=_to_reg;
	by independent_variable;
run;

* find the best model in terms of rsquare (correlation) and then output its coefficients;
proc reg data=_to_reg(where=(_binary_flag=0)) outest=_model_est corr edf noprint;
	by independent_variable;
	model &dep_var. = sqrt log inv lin /*bc:*/ / selection = RSQUARE BEST=1 stop=1;
run;



* use the datasets to create macro variables that can be called directly on the input dataset;
data dset_to_call_execute;
	merge _model_est(in=a) _missing_means(in=b);
	by independent_variable;
run;

data transforms_selected;
set dset_to_call_execute end=EOF;
array _est {4} sqrt log inv lin;
if _n_ = 1 then call execute("data &wideout.(keep=&id. &dep_var. &_nonbin_vars. &_bin_vars.); set &data.;");

if _binary_flag = 0 then do i = 1 to dim(_est);
  if not missing(_est[i]) then do;
	* missing;
	call execute("if missing("||independent_variable||") then "||independent_variable||"=(coalesce(&dep_var.,"||mean||")-"||intercept||")/"||_est[i]||";");

	* transformations;
  	* dont look for lin because if it is lin then there is no transformation;
  	if strip(vname(_est[i])) = "sqrt" then call execute("if "||independent_variable||"<0 then "||independent_variable||" = 0;"||independent_variable||"=sqrt("||independent_variable||");");
	if strip(vname(_est[i])) = "log" then call execute("if "||independent_variable||"<0 then "||independent_variable||" = 0;"||independent_variable||"=log("||independent_variable||"+0.1);");
  	if strip(vname(_est[i])) = "inv" then call execute(independent_variable||"=(1/("||independent_variable||"+0.1));");
	
	transformation=vname(_est[i]);
	* excape loop;
	i = dim(_est);
  end;
end;
else do;
	call execute(independent_variable||"=coalesce("||independent_variable||","||mean||");");
end;
if EOF then call execute("run;");
run;


%mend;

** test on the GMI data;
*directory -- this should ususally not be changed -- should flow from the macro variables defined above;
/*%let directory = /kroger/Lev1/analysis/mp/gmi_m26/&project.;*/
/**/
/**libname;*/
/*libname gmi "&directory./sasdata";*/
/**/
/**/
/**/
/**/
/*data test;*/
/*	do i = 1 to 5;*/
/*		if i = 2 then i = 5;*/
/*		put "test";*/
/*	end;*/
/*run;*/

%macro auto_transformations_loop(data=, id=, dep_var=, indep_var=, longout=longout, wideout=wideout);
	
%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/data_vars_to_macro_vars.sas";
%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/list_macros.sas";
*find binary_vars-- this makes a macro variable called bin_vars ;
%data_vars_to_macro_vars(data=&data., var=&indep_var., binary_name=_bin_vars, non_binary_numeric_name=_nonbin_vars);

%do i = 1 %to %sysfunc(countw(&_bin_vars.));
	%let thisvar= %scan(&_bin_vars., &i.);
* id is a unique identifier for each row;

	%auto_transformations_bin(data=&data., id=&id., dep_var=&dep_var., _bin_vars=&thisvar., wideout=_w_&i.);


%end;

%do j = 1 %to %sysfunc(countw(&_nonbin_vars.));
	%let thisvar= %scan(&indep_var., &j.);
	%let i= %eval(&i.+1);
* id is a unique identifier for each row;

	%auto_transformations_nonbin(data=&data., id=&id., dep_var=&dep_var., _nonbin_vars=&thisvar., wideout=_w_&i.);

%end;


data &wideout.;
	merge _w_1-_w_&i.;
	by consumer_guid;
run;

%mend;
