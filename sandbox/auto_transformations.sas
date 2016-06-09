***********************************************************************************************************************************
***********************************************************************************************************************************
macro_name: 		auto_transformations
author:				Brian Ritz (brian.ritz@8451.com)
purpose:			transform independent variables to better conform to a linear pattern with a specified dependent variable before a regression
					via either a log, square root, or inverse transformation

					Imputes missing values for the independent variables based on the chosen transformation and simple regression derived from the present non-missing values
					and the dependent variable value of the observation with the missing independent variable
					
parameters:
data=...............The input dataset to the macro 
						This will at least have:
							one column that identifies a unique row, 
							one column that represents the dependent variable 
							one or more columns that represent the independent variables to be transformed

id=.................The name of the column that identifies a unique row or observation in the input dataset

dep_var=............The name of the column in the input dataset that identifies the dependent variable

indep_var=..........The name of the column(s) in the input dataset that identify the independent variable(s)
						If there is more than 1 independent variable to be transformed then list them all space separated, example: indep_var=var1 var2 var2,

out=auto_transformations_output .......the name of the output dataset that will contain the dependent variable and the transformed independent variables from the input dataset

out_info=infoout....The name of the output dataset that will contain information on which transfromations were chosen and how means were imputed

groups=100..........The number of groupings in the output plots showing the selected tranformations

outlier_cut=100.....The percentile cutoff for outliers -- 100 means no outliers taken out (default 100)

plot_pdf_out=.......The filename of the output pdf showing the plots of the variables and potential tranfromations as well as means, if omitted no plots are created

***********************************************************************************************************************************
***********************************************************************************************************************************
;
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
/*%let id= name;*/
/*%let groups=100;*/
/*%let outlier_cut=100;*/
/*%let out_info=infoout;*/

/** try all transformations;*/
/*%let longout=test123;*/
/*%let data=sasdata.out_11_all_model_data;*/
/*%let dep_var= pgroup_1;*/
/*%let indep_var= cpn_pb_p cpn_prog_p FIRST_C42_SUBSCRIPTION_SAS CENSUS_MISSING_IND;*/

* TODO: MAKE COMPATABLE WITH > 1 DEPENDENT VARS;
* this has percent suffix;
/*options mprint mlogic;*/


%macro auto_transformations(data=, id=, dep_var=, indep_var=, out=auto_transformations_output, out_info=infoout, groups=100, outlier_cut=100, plot_pdf_out=%str());
%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/data_vars_to_macro_vars.sas";
%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/list_macros.sas";
* id is a unique identifier for each row;
*find binary_vars-- this makes a macro variable called bin_vars ;
%data_vars_to_macro_vars(data=&data., var=&indep_var., binary_name=_bin_vars, non_binary_numeric_name=_nonbin_vars);

%let _nonbin_vars = %trim(&_nonbin_vars.);
%let _bin_vars = %trim(&_bin_vars.);

*make all transformations -- we will pick best later;
data _to_reg(keep= &id. &dep_var. sqrt log inv lin _binary_flag independent_variable)
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

  retain _rt _num _rt_b _M_b _num_b;

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

proc sort data=_missing_means;
  by independent_variable;
run;

proc sort data=_to_reg;
	by independent_variable;
run;



**********************************************;
* ranks to get rid of outliers and for plots;

proc rank data=_to_reg(where=(_binary_flag=0))  out=_to_reg groups=100;
	by independent_variable;
	var lin;
	ranks rank_for_outlier;
run;
proc rank data=_to_reg(where=(_binary_flag=0))  out=_to_reg groups=&groups.;
	by independent_variable;
	var lin;
	ranks rank;
run;

* 4 models for each independent variable (no outliers included);
proc reg data=_to_reg(where=(_binary_flag=0 and rank_for_outlier < &outlier_cut.)) outest=_reg_estimates  rsquare noprint;
	by independent_variable;
	lin: model &dep_var. = lin ;
	log: model &dep_var. = log;
	sqrt: model &dep_var. = sqrt;
	inv: model &dep_var. = inv;
run;

* find the best model in terms of rsquare (correlation) and then output its coefficients;

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

* model label and model color are for the plots -- this dataset will drive a call execute to create all the plots;
data _reg_estimates;
	set _reg_estimates;
	beta1 =coalesce(lin, sqrt, inv, log);
run;

proc sql;
	create table _model_est as select * from _reg_estimates group by independent_variable having _rsq_=max(_rsq_);
quit;

************;
** only run if we need plots;
%if %quote(&plot_pdf_out.) ne %str() %then %do;

* model label and model color are for the plots -- this dataset will drive a call execute to create all the plots;
data _reg_estimates(keep=independent_variable beta1 intercept _rsq_ _model_ model_label model_color pretty_rsq);
	set _reg_estimates;
	length model_label $12;
	length model_color $8;
	beta1 =coalesce(lin, sqrt, inv, log);
	model_label=put(strip(_model_), $model.);
	model_color=put(strip(_model_), $col.);
	pretty_rsq = put(_rsq_, best6.5);
run;

proc means data=_to_reg(where=(rank_for_outlier < &outlier_cut.)) noprint;
	by independent_variable;
	var &dep_var. lin;
	class  rank;
	output out=_means_for_plot mean= n(lin)=n_lin;
run;

* add in the transformed variables for the plot;
data _means_for_plot;
	merge _means_for_plot(in=a) _missing_means(in=b);
    by independent_variable;
    sqrt = sqrt(lin);								
    log = log(lin+0.01);
    inv = (1/(lin+0.01));
    if a;
run;

* call execute creates a dataset with the transformed means according to the regression results that will go into plot;
data _null_;
	set _reg_estimates end=EOF;
	if _n_ = 1 then call execute("data _plot_dataset; set _means_for_plot(where=(rank ne .));xvar=lin;");
	call execute("if independent_variable='"||strip(independent_variable)||"' then "||strip(_model_)||"="||intercept||"+("||beta1||"*"||strip(_model_)||");");
	if EOF then call execute("run;");
run;


ODS PDF FILE = "&plot_pdf_out.";

* call execute creates a plot for every independent variable;
data _null_;
	set _reg_estimates;
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
%end;
* end of making plots;
**********************************************;

/*proc datasets lib=work; */
/*    delete _to_reg;*/
/*run;*/

* use the datasets to create macro variables that can be called directly on the input dataset;
data dset_to_call_execute;
	merge _model_est(in=a) _missing_means(in=b);
	by independent_variable;
run;


* this makes a function called lin available to the data step -- the function does nothing, just returns the input;
* convenient to call this so the code in the datastep is simpler;
proc fcmp outlib=work.functions.samples;
function lin(x);
  
  return(x);
endsub;
quit;
options cmplib=work.functions;


* call execute sets the original dataset and applies the correct transform based on if logic in the dset_to_call_execute dataset;
data &out_info.(keep= independent_variable _binary_flag mean transformation imputed_missing_transformed imputed_missing_untransformed);
	set dset_to_call_execute end=EOF;
    length transformation $12;
	if _n_ = 1 then do;
		call execute("data &out.(keep=&id. &dep_var. &_nonbin_vars. &_bin_vars. compress=BINARY); set &data.;");
		%if &_nonbin_vars. ne %str() %then %do;
		call execute("length &_nonbin_vars. 8.; ");
		%end;
		
  		%if &_bin_vars. ne %str() %then %do;
		call execute("length &_bin_vars. 3.;");
		%end;	
	end;
	if _binary_flag = 0 then do;

		* you may have negatives in the square roots and logs --this is ok because we are imputing based on the dependent variable;
		* it will not affect the parameter estimates because it will be in line with whatever linear estimate we achieve through regression on the transfromed dataset;

		* fix if the independent variable is missing by using the results from the regression to engineer the transformed variable;
		call execute("if missing("||strip(independent_variable)||") then "||strip(independent_variable)||"=(coalesce(&dep_var.,"||mean||")-"||intercept||")/"||beta1||";");
		* this is transformed because we are generating the independent variable backwards from the dependent variable;
		* so when we go backwards with the parameter estimates that were estimated on transformed variables, we get the transfromed variable back;
		* this is the imputation for the independent variable when the dependent and the independent variable are missing;
		imputed_missing_transformed = ((mean-intercept)/beta1);  

		* transformations;
	  	* dont call execute for lin because if it is lin then there is no transformation;
	  	if strip(_model_) = "sqrt" then do;
			call execute("else do; if "||strip(independent_variable)||"<0 then "||strip(independent_variable)||" = 0;"||strip(independent_variable)||"=sqrt("||strip(independent_variable)||");end;");
			imputed_missing_untransformed = (imputed_missing_transformed)**2;
		end;
		if strip(_model_) = "log" then do;
			call execute("else do;if "||strip(independent_variable)||"<0 then "||strip(independent_variable)||" = 0;"||strip(independent_variable)||"=log("||strip(independent_variable)||"+0.01);end;");
			imputed_missing_untransformed = exp(imputed_missing_transformed)-0.01;
		end;
	  	if strip(_model_) = "inv" then do;
			call execute("else "||strip(independent_variable)||"=(1/("||strip(independent_variable)||"+0.01));");
		    imputed_missing_untransformed = (1/(imputed_missing_transformed))-0.01;
		end;
	  	if strip(_model_) = "lin" then do;
			* do not need a call execute here because the independent variable should not be transformed 
				-- else statements are optional and we will have another if before the next else, so not worried about an else;
			imputed_missing_untransformed = imputed_missing_transformed;
		end;

		transformation=put(strip(_model_), $model.);

	end;
	else do;
		call execute(independent_variable||"=coalesce("||independent_variable||","||mean||");");
		transformation="Binary";
		imputed_missing_untransformed = mean;
		imputed_missing_transformed=imputed_missing_untransformed;
	end;
	if EOF then call execute("run;");
run;


%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/record.sas";
%let __mname = %nrquote(&sysmacroname.);
%record(&__mname.);

%mend;
