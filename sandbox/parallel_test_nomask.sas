%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/sandbox/parallel_20160226_nomask.sas";


libname par "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/parallel_directory";

data par.first_dat;
	x = "this was written outside";
	y = "this was also written outside";
run;

%macro to_write(put_this, putthis2, third);

	data par.&put_this.;
		x = "&put_this.";
		y = "&putthis2.";
		z = "&third.";
		output;
	run;

	* sleep is here to test whether the program can accurately detect when the program is finished;
	data _null_;
		slept = sleep(30000);
	run;

%mend;

data par.second_dat;
	x = 'written outside second';
run;

options mprint;

data pd;
	put_this="msg1";putthis2="messag12";third=31; output;
	put_this="ms21";putthis2="messag22";third=32; output;
	put_this="ms31";putthis2="messag32";third=33; output;
	put_this="ms41";putthis2="messag42";third=34; output;
run;

%parallel(macro=to_write, param_dset = pd, stagger=0, cleanup=N);


data par.third_dat;
	x ='this was written 3rd after the parallel ran nomask';
run;
