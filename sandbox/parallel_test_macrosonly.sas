%macro to_write(put_this, putthis2, third);

	data par.&put_this.;
		x = "&put_this.";
		y = "&putthis2.";
		z = "&third.";
		output;
	run;

	* sleep is here to test whether the program can accurately detect when the program is finished;
/*	data _null_;*/
/*		slept = sleep(20000);*/
/*	run;*/

%mend;
