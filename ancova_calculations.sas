****************************************************************************************************************************************
****************************************************************************************************************************************
project: 	2015 GMI Phil
program: 	20_ancova_calculations
purpose:	perform the ancova calculations for every product group, time period, customer group
*******************************************************************************************
author:		Brian Ritz*********************************************
****************************************************************************************************************************************
;

* default is output to 95 percent confidence intervals;

** NOTE:
I did not use a by statement and instead opted for different parameters for each product_group variable_name customer_group and time_group.
I did this so we could loop through multiple variables for each group,
for example customer_group=customer_group_1 customer_group_2 would take each of those two variables separately
;
%macro ancovas(data=, out=, time_group=time_group, 
product_group=product_group, variable_name=variable_name, customer_group=customer_group, 
post_period=, pre_period=, test_control=);

%include "./format_macro_vars.sas";
%include "./create_formats.sas";

proc delete data=&out.;
run;

%let _num_cols_cust_grps=%sysfunc(countw(&customer_group.));
%let _num_cols_prd_grps=%sysfunc(countw(&product_group.));
%let _num_cols_time_grps=%sysfunc(countw(&time_group.));
%let _num_cols_var_grps=%sysfunc(countw(&variable_name.));

* this is the number of groups that will have two columns to identify them on the output -- the groups which are identified by more than just one column;
%let _num_double_cols=%eval((&_num_cols_cust_grps > 1)+(&_num_cols_prd_grps. > 1)+(&_num_cols_time_grps.>1) + (&_num_cols_var_grps. > 1));

%do t = 1 %to &_num_cols_time_grps.;
%do p = 1 %to &_num_cols_prd_grps.;
%do v = 1 %to &_num_cols_var_grps.;
%do c = 1 %to &_num_cols_cust_grps.;

%let _cust_grp = %scan(&customer_group., &c.);
%let _prd_grp = %scan(&product_group., &p.);
%let _time_grp = %scan(&time_group., &t.);
%let _var_grp = %scan(&variable_name., &v.);

%put ===STARTING CUSTOMER GROUP: &_cust_grp., PRODUCT_GROUP: &_prd_grp., TIME_GROUP: &_time_grp., VARIABLE_GROUP: &_var_grp.===;

* if statment to save time and not sort orig dataset every time;
%if (&c. = 1 and &p.=1 and &t.=1 and &v.=1) %then %do;
proc sort data=&data. out=_inputs;
	by &_time_grp. &_prd_grp. &_var_grp. &_cust_grp. &test_control.;
run;
%end;
%else %do;
proc sort data=_inputs;
	by &_time_grp. &_prd_grp. &_var_grp. &_cust_grp. &test_control.;
run;
%end;

proc glm data=_inputs
alpha=0.1
outstat = _one ;
	by &_time_grp. &_prd_grp. &_var_grp. &_cust_grp.;
	class &test_control.;
	model &post_period. = &pre_period. &test_control. / ss3 clparm solution;
	lsmeans &test_control. / pdiff adjust=t stderr cov out=_two cl tdiff ;
	means &test_control.;
	ods output LSMeanDiffCL=_three Means=_counts;
run;


proc means data=_inputs  nway noprint;
	by &_time_grp. &_prd_grp. &_var_grp. &_cust_grp. &test_control.;
	var &pre_period. &post_period.;
	output out = _four mean(&pre_period.)= unadjusted_pre mean(&post_period.) = unadjusted_post;
run;

*get significance;
data _one1 (keep= pvalue stat_test &_time_grp. &_prd_grp. &_var_grp. &_cust_grp. );
	set  _one (where = (_source_ = "&test_control.")) ;
	format confidence percent10.2 stat_test $15. pvalue 8.5;
	confidence = 1-prob;
	if confidence ge 0.9 then stat_test = 'Significant' ;
		else if confidence ge 0.8 then stat_test = 'Directional' ;
		else stat_test = 'Not Significant' ;
	pvalue = prob*1;
run;


data _one2 (keep= N &_time_grp. &_prd_grp. &_var_grp. &_cust_grp. );
	set _one (where = (_source_ = 'ERROR')) ;
	N = DF+3; 
	test_households=N/2;
	call symputx("_df", DF);
run;

* get critical t values for confidence intervals;

*get uplift;
data _two2 /*(keep= &test_control. lsmean &time_group. &product_group. &_cust_grp. &variable_name. )*/ ; 
	set _two(rename=(lsmean=mean));
	CI_l = mean+tinv(0.05,&_df.)*stderr;
	CI_h = mean+tinv(0.95,&_df.)*stderr;
run;


*make sure control is first;
proc sort data=_two2; 
	by &_time_grp. &_prd_grp. &_var_grp. &_cust_grp &test_control.;
run; 

proc transpose data=_two2
								out=_two3
								prefix = __pr;
	by &_time_grp. &_prd_grp. &_var_grp. &_cust_grp. ;
	var mean CI:;
	id &test_control.;
run;

proc contents data=_two3 out=_two3_vars;
run;

proc sql;
	select name into :_hhvars separated by " " from _two3_vars where name like "__pr%";
run;

data _two4/*(keep=_name_ tc value &time_group. &product_group. &variable_name. &_cust_grp. )*/;
	set _two3 end=eof;
	by &_time_grp. &_prd_grp. &_var_grp. &_cust_grp. ;
	length tc $32;
	length newvarname $32;
	array _arr {*} &_hhvars.;
	do i = 1 to dim(_arr);
		tc = substr(vname(_arr[i]), 5, length(vname(_arr[i]))-4);
		value=_arr[i];
		newvarname= catx("_", tc, _name_);
		output;

		if eof then do;
			if upcase(substr(tc,1,1))="C" then call symput("_ctrl_v", strip(tc));
			if upcase(substr(tc,1,1))="T" then call symput("_test_v", strip(tc));
		end;
	end;
run;

proc transpose data=_two4 out=_two5;
	by &_time_grp. &_prd_grp. &_var_grp. &_cust_grp ;
	var value;
	id newvarname;
run;

proc sort data=_two5;
	by &_time_grp. &_prd_grp. &_var_grp. &_cust_grp.;
run;

proc sort data=_three;
	by &_time_grp. &_prd_grp. &_var_grp. &_cust_grp.;
run;

data _two6(keep=&_time_grp. &_prd_grp. &_var_grp. &_cust_grp. 
&_ctrl_v.: &_test_v.: UpperCL lowerCL uplift: rename=(UpperCL = uplift_ci_h lowerCL=uplift_ci_l 
											&_test_v._mean=TEST_mean &_test_v._ci_l=TEST_CI_L &_test_v._ci_h=TEST_CI_H
											&_ctrl_v._mean=CONTROL_mean &_ctrl_v._ci_l=CONTROL_CI_L &_ctrl_v._ci_h=CONTROL_CI_H)) ;
	merge _two5 _three;  * three is the lsmeans differences;
	by &_time_grp. &_prd_grp. &_var_grp. &_cust_grp. ;
	uplift_mean = &_test_v._mean-&_ctrl_v._mean;
	uplift_pct=uplift_mean / &_ctrl_v._mean;

	* correct the +- direction of the lsmeans differences if needed;
	direction= uplift_mean / abs(uplift_mean);
	difference_direction = difference / abs(difference);
	if difference_direction ne direction then do;
		u2 = upperCL;
		UpperCL = LowerCL*(-1);
		difference=difference*(-1);
		LowerCL = u2*(-1);
	end;
run;


*get the unadjusted numbers;
proc sort data=_four;
	by &_time_grp. &_prd_grp. &_var_grp. &_cust_grp. &test_control.;
run;
proc sort data=_counts(keep= &_time_grp. &_prd_grp. &_var_grp. &_cust_grp. &test_control. N);
	by &_time_grp. &_prd_grp. &_var_grp. &_cust_grp. &test_control.;
run;

*transpose through data step;
data _four2(drop=&test_control. unadjusted_pre unadjusted_post _: N);
	merge _four(in=a) _counts(in=b);
	by &_time_grp. &_prd_grp. &_var_grp. &_cust_grp. &test_control.;

	retain test_unadjusted_post test_unadjusted_pre cont_unadjusted_post cont_unadjusted_pre cont_N test_N;
	if upcase(substr(&test_control.,1,1)) = "C" then do;
		cont_unadjusted_post = unadjusted_post;
		cont_unadjusted_pre = unadjusted_pre;
		cont_N=N;
	end;

	if upcase(substr(&test_control.,1,1)) = "T" then do;
		test_unadjusted_post = unadjusted_post;
		test_unadjusted_pre = unadjusted_pre;
		test_N=N;
	end;
	if last.&_cust_grp. then output;
run;


*combine output datasets;
data _five;

	merge _two6 _one1 _one2 _four2;
	by &_time_grp. &_prd_grp. &_var_grp. &_cust_grp.;
run;

* figure if the customer group and time periods and product groups and variable names are numeric;
proc contents data=_five out=_five_vars;
run;

proc sql;
	select case when type=2 then "length=40" else "length=8" end into : _cust_grp_len from _five_vars where upcase(name)=upcase("&_cust_grp.");
	select case when type=2 then "length=40" else "length=8" end into : _prod_grp_len from _five_vars where upcase(name)=upcase("&_prd_grp.");
	select case when type=2 then "length=40" else "length=8" end into : _time_grp_len from _five_vars where upcase(name)=upcase("&_time_grp.");
	select case when type=2 then "length=40" else "length=8" end into : _var_grp_len from _five_vars where upcase(name)=upcase("&_var_grp.");
quit;

*reorder vars;
proc sql noprint;
	create table _subtotal_ancova_results
	as select 			"&_cust_grp." as customer_variable length=50,
						"&_time_grp." as time_variable length=50,
						"&_prd_grp." as product_variable length=50,
						&_cust_grp. as customer_cut &_cust_grp_len.,
						&_time_grp. as time_cut &_time_grp_len.,
						&_prd_grp. as product_cut &_prod_grp_len.,
						&_var_grp.  &_var_grp_len.,
						TEST_mean, CONTROL_mean, TEST_CI_L, TEST_CI_H, CONTROL_CI_L, CONTROL_CI_H, 
						uplift_mean,
						uplift_pct, uplift_ci_l, uplift_ci_h, 
						pvalue, stat_test length=40,
						n, cont_N as control_N, test_N,
						test_unadjusted_post,
						test_unadjusted_pre,
						cont_unadjusted_post,
						cont_unadjusted_pre
	from _five;
quit;

proc append base = &out. data=_subtotal_ancova_results;
run;

%put ===FINISHED CUSTOMER GROUP: &_cust_grp., PRODUCT_GROUP: &_prd_grp., TIME_GROUP: &_time_grp., VARIABLE_GROUP: &_var_grp.===;

%end;
%end;
%end;
%end;

proc datasets lib=work;
	delete _one _one1 _one2 _two _two2 _two3 _two3_vars _two4 _two5 _two6 _three _four _four2 _five _five_vars _subtotal_ancova_results _inputs _counts;
run;

%mend;

/*%ancovas(*/
/*data=sasdata.out_19b_inputs,*/
/*out=test_ancovas,*/
/*time_group=time_per, */
/*product_group=product_group,*/
/*variable_name=variable_name,*/
/*customer_group=customer_group_8 customer_group_9,*/
/*post_period=value,*/
/*pre_period=value_pre,*/
/*test_control=hhgroup*/
/*);*/
/**/

%macro ancovas_parallel(
data=,
out=,
time_group=time_group, 
product_group=product_group, 
variable_name=variable_name, 
customer_group=customer_group,
post_period=, 
pre_period=, 
test_control=,
filename_prefix=hh_test_control_match,allmail=Y,
num_dhchains=8,
create_index=N);

%include "./format_macro_vars.sas";
%include "./data_vars_to_macro_vars.sas";


	%let by=&product_group. &time_group. &variable_name.;


	* find directory of prefix for the file (file must be permanent);
	%let _lib=%substr(&data., 1, %index(&data.,%str(.))-1);
	%let _path2fil = %sysfunc(pathname(&_lib.));
	
	%let _lib2=%substr(&out., 1, %index(&out.,%str(.))-1);
	%let _path2fil2 =  %sysfunc(pathname(&_lib2.));

	* file name of the out file;
	%let _out1=%sysfunc(reverse(%substr(%sysfunc(reverse(&data.)),1, %index(%sysfunc(reverse(&data.)),%str(.))-1)));
	%let _out2=%sysfunc(reverse(%substr(%sysfunc(reverse(&out.)),1, %index(%sysfunc(reverse(&out.)),%str(.))-1)));


	* create an index on the data input so we can subset faster in all of the child programs;
	%if &create_index.=Y %then %do;
	proc datasets library=&_lib.;
		modify &_out1.;
		index create ancind=( &by. );
	run;
	%end;

	proc sort data=&data.(keep=&by.) out=_force_combos nodupkey;
		by &by.;
	run;

	* find current directory of current program;
	* if in batch -- put file in;
	data _null_;
		set sashelp.vextfl(where=(upcase(xpath) like '%.SAS'));
		if index(upcase(xpath), "AUTOEXEC") = 0 then call symput('_original_sas_prog', strip(xpath));
	run;

	%let first_slash = %index(%sysfunc(reverse(&_original_sas_prog.)),/);
	%let ln = %length(&_original_sas_prog.);
	%let par_directory = %substr(&_original_sas_prog.,1, %eval(&ln.-&first_slash.+1));
	%let par_directory = &par_directory.&filename_prefix./;
	x "mkdir &par_directory.";
	%put &par_directory.;
	%put &_original_sas_prog.;
	* loop through all combos;
	proc sql;
		select count(*) into : _numruns from _force_combos;
	quit;

	%do i = 1 %to &_numruns.;
	
		data _null_;
			set _force_combos(firstobs=&i. obs=&i.);

			%do j = 1 %to %sysfunc(countw(&by.));
				%if %getType(&data., %scan(&by., &j.))=C %then %do;
					if missing(%scan(&by., &j.)) then do;
					call symput("_var_&j.", "''");
					end;
					else do;
					call symput("_var_&j.", "'"||strip(%scan(&by., &j.))||"'");
					end;
				%end;
				%else %do;
					if missing(%scan(&by.,&j.)) then do;
					call symput("_var_&j.",".");
					end;
					else do;
					call symput ("_var_&j.", %scan(&by., &j.));
					end;
				%end;
			%end;
		run;

		data _null_;
			length x $4000;
			file "&par_directory.&filename_prefix._&i..sas";
			put "libname &_lib. '&_path2fil.';";
			%if &_lib. ne &_lib2. %then %do;
			put "libname &_lib2. '&_path2fil2.';";
			%end;
			put "filename anc '/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/ancova_calculations.sas';";
			put "%include anc;";  * the call to parallel will be masked;
			put "data subset; set &data.;";
			put "where ";
			%do j = 1 %to %sysfunc(countw(&by.));
				put "%scan(&by., &j.) = &&&_var_&j.. ";
				%if &j. ne %sysfunc(countw(&by.)) %then %do;
				put " and ";
				%end;
				%else %do;
				put ";";
				put "run;";
				%end;
			%end;
			x = "%"||"ancovas(";
			x = strip(x);
			put x;
			put "data=subset,";
			put "out=&out._&i.,";
			put "time_group=&time_group.,";
			put "variable_name=&variable_name.,";
			put "customer_group="; 
			%do _j = 1 %to %sysfunc(countw(&customer_group.));
			%let _thisc =%scan(&customer_group.,&_j.) ;
			put "&_thisc.  ";
			%end;
			put ",";
			put "product_group=&product_group.,";
			put "post_period=&post_period.,";
			put "pre_period=&pre_period.,";
			put "test_control=&test_control.);";

		run;
	%end;

%if &allmail.=Y %then %let _allmail = -allmail;
%else %let _allmail=;
data _null_;
	file "&par_directory.&filename_prefix._driver.py";
	put "import os";
	put "import math";
	put "NUM_DHCHAINS = &num_dhchains.";
	put "prog_names = [fil for fil in os.listdir(os.getcwd()) if fil.endswith('.sas')]";
	put "prog_names = sorted(prog_names, key=lambda x: int(x.replace('.sas','').replace('&filename_prefix._','')))";
	put "prog_nums = [fil.replace('.sas','').replace('&filename_prefix._','') for fil in prog_names]";
	put "chain_size = int(math.ceil(float(len(prog_names)) / float(NUM_DHCHAINS)))";

	put "# filter the list to exclude progs that already ran";

	put "already_ran = [fil.replace('.sas7bdat','').replace('&_out2._','') for fil in os.listdir('&_path2fil2.') if fil.endswith('.sas7bdat')]";
	put "already_ran = sorted(already_ran, key=lambda x: int(x))";

	put "to_go = [num for num in prog_nums if num not in already_ran]";

	put "new_progs = ['&filename_prefix._'+str(i)+'.sas' for i in to_go]";
	put "


	";

	put "def chunks(l, n):";
	put "    for i in xrange(0, len(l), n):";
	put "        yield l[i:i+n]";
	put "


	";

	put "chain_commands = ['dhchain -ts &_allmail. ' + ' '.join(l) for l in list(chunks(new_progs, chain_size))]";
	put "for command in chain_commands:";
	put "    os.system(command)";
run;


%mend;
