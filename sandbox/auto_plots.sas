
%macro auto_plots(data=, id=, dep_var=, indep_var=, pdf_results=, groups=100, outlier_cut=100);
%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/data_vars_to_macro_vars.sas";
%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/list_macros.sas";
* id is a unique identifier for each row;

*find binary_vars-- this makes a macro variable called bin_vars ;
%data_vars_to_macro_vars(data=&data., var=&indep_var., binary_name=_bin_vars, non_binary_numeric_name=_nonbin_vars);
/*%put &_nonbin_vars.;*/

%let _nonbin_vars = %trim(&_nonbin_vars.);
%let _bin_vars = %trim(&_bin_vars.);

%put &_nonbin_vars;
%put &_bin_vars.;
*make all transformations -- we will pick best later -- also find the mean when the independent variable is missing;
data _to_reg(keep= &id. &dep_var. sqrt log inv lin /*bc:*/ _binary_flag independent_variable)
      _missing_means(keep=independent_variable mean _binary_flag);
  set &data. end=eof;
  length independent_variable $32;
  length _binary_flag 3.;
  length sqrt log inv lin 8.;

  * non - binary variables;
  array _ind {*} &_nonbin_vars.;
  array _rt {*} %suffix(_m, &_nonbin_vars.);  *running total of dep var for when it is missing;
  array _num {*} %suffix(_n, &_nonbin_vars.);


  %if &_bin_vars. ne %str() %then %do;
	* binary variables;
	array _ind_b {*} &_bin_vars.;
	* multidimensinal array will calcualte the mean for 0s and mean for 1s;
	array _rt_b {*} %suffix(_m, &_bin_vars.);                                                               *running total of dep var for when it is missing;
	array _M_b {0:3, %sysfunc(countw(&_bin_vars.))} %suffix(_0, &_bin_vars.) %suffix(_1, &_bin_vars.) %suffix(_0n, &_bin_vars.) %suffix(_1n, &_bin_vars.);        *running total of dep var for when it is not missing;
	array _num_b {*} %suffix(_n, &_bin_vars.);
  %end;
  * box cox transforms;
  array _bc {-1:5} bc_1-bc_7;

  retain _rt _num _rt_b _M_b _num_b;
  do i = -1 to 5 ;
    _bc[i] = .;
  end;
  sqrt=.; log=.; inv=.; lin=.;

  * binary variables;
  %if &_bin_vars. ne %str() %then %do;
  do i = 1 to dim(_ind_b);
	independent_variable = vname(_ind_b[i]);
    lin = _ind_b[i];
    if ~missing(_ind_b[i]) and ~missing(&dep_var.) then do;
	  * running totals and counts for mean when indep var is 0 and when indep var is 1;
      _M_b[_ind_b[i], i] = sum(_M_b[_ind_b[i], i], &dep_var.);
      _M_b[_ind_b[i]+2, i] = sum(_M_b[_ind_b[i]+2, i], 1);
    end;
    else if ~missing(&dep_var.) then do;  
		* mean when independent variable is missing;
      _rt_b[i] = sum(_rt_b[i], &dep_var.);
      _num_b[i] = sum(_num_b[i], 1);
    end;
    _binary_flag=1;
	if ~missing(&dep_var.) and ~missing(_ind_b[i]) then    
		output _to_reg;

  end;
  %end;

  * non-binary variables;
	do i = 1 to dim(_ind);
  
    * box cox transform;
    do j = -1 to 5;
      if j ne 0 then do;
        _bc[j] = (_ind[i]**j - 1) / j ;
      end; 
      else do;
        _bc[j] = log(_ind[i] + 0.1);
      end;  
    end;
	s = .1;
    * other transforms;
		sqrt = sqrt(_ind[i]);								
		log = log(_ind[i]+0.01);
		inv = (1/(_ind[i]+0.01));
		lin = _ind[i];

		independent_variable = vname(_ind[i]);

	    * tally up the sum of the dependent variables when the independent variable is missing 
	    (so we can get the mean);
	    if missing(_ind[i]) and ~missing(&dep_var.) then do;  
	      _rt[i] = sum(_rt[i], &dep_var.);
	      _num[i] = sum(_num[i], 1);
	    end;
	    _binary_flag=0;
		if ~missing(&dep_var.) and ~missing(_ind[i]) then
			output _to_reg;
	end;
	if eof then call symputx("_missing_mean", missing_tot/missing_n);
*non -binary vars;
  if eof then do i = 1 to dim(_num);
    independent_variable = vname(_ind[i]);
    if _num[i] > 0 then mean = _rt[i]/_num[i];
    else mean = .;
	_binary_flag=0;
    output _missing_means;
  end;
*binary vars;
  %if &_bin_vars. ne %str() %then %do;
  if eof then do i = 1 to dim(_num_b);
    independent_variable = vname(_ind_b[i]);
    if _num_b[i] > 0 then do;
		mean = _rt_b[i]/_num_b[i];
	    zero_mean = _M_b[0,i] / _M_b[2,i];
	    one_mean = _M_b[1,i] / _M_b[3,i];
	    if abs(one_mean-mean) - abs(zero_mean-mean) > 0 then mean=0;
	    else mean=1;
	end;
    else mean = .;
	_binary_flag=1;
    output _missing_means;
  end;
  %end;
run;

proc sort data=_to_reg; by independent_variable; run;

proc sort data=_missing_means;
  by independent_variable;
run;

/*option to remove outliers using rank*/
proc rank data=_to_reg/*(where=(_binary_flag=0))*/  out=_to_reg  groups=&groups.;
	by independent_variable;
	var lin;
	ranks rank;
run;

proc reg data=_to_reg(where=(/*_binary_flag=0 and */ rank < &outlier_cut.)) outest=_reg_estimates  rsquare;
	by independent_variable;
	lin: model &dep_var. = lin ;
	log: model &dep_var. = log;
	sqrt: model &dep_var. = sqrt;
	inv: model &dep_var. = inv;
run;

proc sql;
	create table _model_est2 as select * from _reg_estimates group by independent_variable having _rsq_=max(_rsq_);
quit;

proc format;
  value  $model 'lin'='Linear'
               	'log'='Log'
               	'sqrt'='Square Root'
               	'inv'='Inverse';
	value $col 	'lin'='bip'
				'log'='vipk'
				'sqrt'='orange'
				'inv'='deeppink';
run;

data _reg_estimates(keep=independent_variable beta1 intercept _rsq_ _model_ model_label model_color pretty_rsq);
	set _reg_estimates;
	length model_label $12;
	length model_color $8;
	beta1 =coalesce(lin, sqrt, inv, log);
	model_label=put(strip(_model_), $model.);
	model_color=put(strip(_model_), $col.);
	pretty_rsq = put(_rsq_, bestd9.7);
run;


proc means data=_to_reg(where=(rank < &outlier_cut.)) noprint;
	by independent_variable;
	var &dep_var. lin;
	class  rank;
	output out=_means_for_plot mean=;
run;

* add in the transformed variables for the plot;
data _means_for_plot;
	merge _means_for_plot(in=a) _missing_means(in=b);
    by independent_variable;
		sqrt = sqrt(lin);								
		log = log(lin+0.01);
		inv = (1/(lin+0.01));
	run;

data _null_;
	set _reg_estimates end=EOF;
	if _n_ = 1 then call execute("data _plot_dataset; set _means_for_plot(where=(rank ne .));xvar=lin;");
	call execute("if independent_variable='"||strip(independent_variable)||"' then "||strip(_model_)||"="||intercept||"+("||beta1||"*"||strip(_model_)||");");
	if EOF then call execute("run;");
run;

/*the pdf output will be written to the destination defined by the results parameter*/
ODS PDF FILE = "&pdf_results.";

/*the output .png image files will be written in the work directory as opposed to permanently saved*/
ods listing gpath="%sysfunc(getoption(work))";

* call execute creates a plot for every independent variable;
data _null_;
	set _reg_estimates end=eof;
	by independent_variable;
	if first.independent_variable then call execute("proc sgplot data=_plot_dataset(where=(independent_variable='"||strip(independent_variable)||"'));
            series x=xvar y= mean / lineattrs=(pattern=2);");
	call execute("series x=xvar y="||strip(_model_)||" / legendlabel='"||strip(model_label)||" Rsq:    "||pretty_rsq||"' lineattrs=(color="||model_color||" thickness=3)
curvelabel='"||model_label||"' name='"||strip(_model_)||"';");
	if last.independent_variable then call execute("scatter x=xvar y=&dep_var. / markerattrs=(symbol=Circlefilled size=10); 
keylegend 'lin' 'log' 'sqrt' 'inv' / across=1;
title 'Binned Scatter Plot and Potential Line Fits for "||independent_variable||"';run;");
run;

ODS PDF CLOSE;

%mend;




/*	proc sgplot data=_plot_dataset(where=(independent_variable=''));*/
/*            series x=xvar y= mean / lineattrs=(pattern=2);;*/
/*	series x=xvar y=||strip(_model_)|| legendlabel=' Rsq:    "||pretty_rsq||"' lineattrs=(color="||model_color||" thickness=3)*/
/*curvelabel=model_label name=);*/
/*scatter x=xvar y=&dep_var. / markerattrs=(symbol=Circlefilled size=10); */
/*keylegend 'lin' 'log' 'sqrt' 'inv' / across=1;*/
/*title 'Binned Scatter Plot and Potential Line Fits for independent_variable';*/
/*run;*/
/*run;*/
