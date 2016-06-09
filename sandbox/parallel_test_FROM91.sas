%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/sandbox/parallel.sas";


libname par "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/parallel_directory";
%macro to_write(put_this, putthis2, third);

	data par.&put_this.;
		x = "&put_this.";
		y = "&putthis2.";
		z = "&third.";
		output;
	run;

	data _null_;
		slept = sleep(20000);
	run;

%mend;

options mprint;
%parallel(macro=to_write, param1=msg1 message2 messagee3 messaged4 newmsg,
param2=second1 second2 second3 secnd4 sc5, stagger=1000, cleanup=N);
