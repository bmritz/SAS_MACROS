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
		slept = sleep(80000);
	run;

%mend;

data par.second_dat;
	x = 'written outside second';
run;

options mprint;
%parallel(macro=to_write, param1=msg1 message2 messagee3 messaged4 newmsg,
param2=second1 second2 second3 secnd4 sc5, stagger=0, cleanup=N);

data par.third_dat;
	x ='this was written 3rd after the parallel ran';
run;
