%macro label_dset(dset=, label_dset=, out=%str());

	%if &out.=%str() %then %let out=&dset.;
	proc sql noprint;
	select catx("=", name, quote(trim(label)))
	  into :label_list separated by " "
	from &label_dset.;
	quit;

	data &out.;
		set &dset.;
		label &label_list.;
	run;
%mend;
