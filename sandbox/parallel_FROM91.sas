* macro parallel;
* brian ritz;
* runs a bunch of macro calls simulataneously in different programs that the macro creates;
* the macros will all run with different parameters;
* you can specify two macro names, and the second macro name will run after all of the first macros are finished.;


%macro parallel(macro=,stagger=0,param1=,param2=,param3=,param4=,param5=, cleanup=Y);
	%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/mask_code.sas";
	
	* we put all of our code inside another macro and mask that macro...;
	* we do this so when the newly created programs include the original program, the parallel macro runs again but the code inside this runpar does not run again;
	* prevents never ending recursion;

	%macro _runpar;
		%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/format_macro_vars.sas";
		
		********** GET THE ORIGINAL PROGRAM FILE -- IE THE PROGRAM THAT WAS BATCHED AND CONTAINED THE PARALLEL MACRO CALL;
		* if in eg -- doesnt work because we cant kick off batch programs on the us-ham-svb-0066 -- just for interactive sessions;
		%if %symexist(_SASPROGRAMFILE) %then %do;
			%put ERROR: YOU CANNOT RUN THE PARALLEL MACRO IN EG;
			%abort;
		%end;
		%else %do;
		* if in batch -- put file in;
			data test;
				set sashelp.vextfl(where=(upcase(xpath) like '%.SAS'));
				if index(upcase(xpath), "KROGER_AUTOEXEC") = 0 then call symput('original_sas_prog', strip(xpath));
			run;
			%single_quote(original_sas_prog, " ");
		%end;

		*************** get the directory of the original sas prog -- this is where we will write out our new files;
		%single_unquote(original_sas_prog, " ");
		%let first_slash = %index(%sysfunc(reverse(&original_sas_prog.)),/);
		%let ln = %length(&original_sas_prog.);
		%let par_directory = %substr(&original_sas_prog.,1, %eval(&ln.-&first_slash.+1));


		*************** check if the parameters are all the same length as we read them into macro vars param_2, param_3, param_4, etc..;
		%do i = 1 %to 4;
			%let iplus1 = %eval(&i.+1);
			%put param&i. is &&param&i..;
			%if &&param&iplus1.. ne %str() %then %do;
				%if %sysfunc(countw(&&param&i..)) ne %sysfunc(countw(&&param&iplus1..)) %then %do;
					%put ERROR: The lists of parameters must all be the same length;
					%abort;
				%end;
			%end;
		%end;
		*************** loop through each file -- one loop for every word in param_2;
		%single_quote(original_sas_prog, " ");
		%let all_new_progs=;
		%let all_new_logs=;
		%do j = 1 %to %sysfunc(countw(&param1.));

			***MAKE THE FILE;
			
			%let progname=&macro._&j.;
			%let filname = &par_directory.&progname..sas;
			%let logpath=&par_directory.&progname..log;

			* append a file name onto a large list to check if it is still running later;

			%let all_new_progs=&all_new_progs. &filname.;
			%let all_new_logs = &all_new_logs. &logpath.;

			* loop through to create all parameters;
			%let p1=;
			%do k = 1 %to 5;
				%let p1=&p1. %scan(&&param&k.., &j.);
				%if &k. ne 5 %then %do;
					%let kplus1=%eval(&k.+1);
					%if &&param&kplus1.. ne %str() %then %let p1=&p1.,;
				%end;
			%end;

			%let macro_call=&macro.(&p1.);

			data _null_;
				length x $400;
				file "&filname.";
				put "filename origfil &original_sas_prog. ;";
				put "%include origfil;";  * the call to parallel will be masked;
				x = "%"||"&macro_call."||";";
				x = strip(x);
				put x;
			run;
		

			***KICK OFF THE FILE;
			%put Now kicking off: &filname.;
			x "/sas/SASHome/SASFoundation/9.3/sas -noterminal &filname. -log &logpath. &";

			*** SLEEP TO STAGGER;
			%if &j. < %sysfunc(countw(&param1.)) %then %do;
				data _null_;
					slept=sleep(&stagger.);
				run;
			%end;
		%end;

		
		options NOQUOTELENMAX;
		* loop to wait until they are all done;
		%single_quote(all_new_progs, " ");
		%let rc=0;
		%put all new progs is: &all_new_progs.;
		%do %while(&rc.=0);

			* wait 2 minutes before checking;
			data _null_;
				slept = sleep(120000);
			run;
			
			* pipe in processes on the linux server and look for the file names;
			filename linux PIPE  'ps -eo command';
			libname sasdata "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/parallel_directory/";

			data _null_;
				infile linux firstobs=2 end=eof;

				length command $50 noterminal $50 program $1000;
				input command $ program;
				length progs_still_running 8.;
				retain progs_still_running;
				if _n_=1 then progs_still_running=0;
				if strip(program) in (&all_new_progs.) then progs_still_running=sum(progs_still_running,1);

				if eof and progs_still_running=0 then do;
					call symput("rc","1");
				end;
			run;


		%end;
		options QUOTELENMAX;

		* consolidate logs into the original programs log;
		options nosource nonotes noquotelenmax;
		%single_quote(all_new_logs, " ");
		%do j = 1 %to %sysfunc(countw(&param1.));

			%let thislog = %scan(&all_new_logs.,&j., %str( ));
			%let thissas = %scan(&all_new_progs.,&j., %str( ));

			%put -----------------------------------------------------------------------------------------------;
			%put ---BEGINNING OF LOG &thislog.---;
			%put -----------------------------------------------------------------------------------------------;
						data _null_;
							infile &thislog.;
							input @1 line $500.;
							put line;
						run;
			%put -----------------------------------------------------------------------------------------------;
			%put ---END OF LOG &thislog.---;
			%put -----------------------------------------------------------------------------------------------;

			%single_unquote(thislog, " ");
			%single_unquote(thissas, " ");

			%if %substr(%upcase(&cleanup.),1,1)=Y %then %do;
			x "rm &thislog.";
			x "rm &thissas.";
			%end;
		%end;
		options source notes quotelenmax;

	%mend _runpar;

	%mask_code(_runpar);

%mend parallel;
