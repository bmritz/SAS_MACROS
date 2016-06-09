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
			data _null_;
				set sashelp.vextfl(where=(upcase(xpath) like '%.SAS'));
				if index(upcase(xpath), "AUTOEXEC") = 0 then call symput('original_sas_prog', strip(xpath));
			run;
			%single_quote(original_sas_prog, " ");
		%end;

		*************** get the directory of the original sas prog -- this is where we will write out our new files;
		%single_unquote(original_sas_prog, " ");
		%let first_slash = %index(%sysfunc(reverse(&original_sas_prog.)),/);
		%let ln = %length(&original_sas_prog.);
		%let par_directory = %substr(&original_sas_prog.,1, %eval(&ln.-&first_slash.+1));
		%let new_dir = %QStrReplace(&original_sas_prog.,.sas,_parallel/);
		%let orig_prog_name = %QStrReplace(&original_sas_prog.,&par_directory.,%str());
		x "mkdir &new_dir.";

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
		%do i = 1 %to %sysfunc(countw(&param1.));

			***MAKE THE FILE;
			
			%let progname=&original_prog_name._&macro._&i.;
			%let filname = &new_dir.&progname..sas;
			%let logpath=&new_dir.&progname..log;

			* append a file name onto a large list to check if it is still running later;

			%let all_new_progs = &all_new_progs. &filname.;
			%let all_new_logs = &all_new_logs. &logpath.;

			* loop through to create all parameters;
			%let _allp=;
			%do _k = 1 %to 5;
				%let _allp=&_allp. %scan(&&param&_k.., &j.);
				%if &_k. ne 5 %then %do;
					%let _kplus1=%eval(&_k.+1);
					%if &&param&_kplus1.. ne %str() %then %let _allp=&_allp.,;
				%end;
			%end;

			%let macro_call=&macro.(&_allp.);

			data _null_;
				length x $4000;
				file "&filname.";
				put "filename origfil &original_sas_prog. ;";
				put "%include origfil;";  * the call to parallel will be masked;
				x = "%"||"&macro_call."||";";
				x = strip(x);
				put x;
			run;
		
			*** SLEEP TO STAGGER;
/*			%if &j. < %sysfunc(countw(&param1.)) %then %do;*/
/*				data _null_;*/
/*					slept=sleep(&stagger.);*/
/*				run;*/
/*			%end;*/
		%end;

		%if &allmail.=Y %then %let _allmail = -allmail;
		%else %let _allmail=;
		data _null_;
			file "&new_dir.&original_prog_name._&macro._driver.py";
			put "import os";
			put "import math";
			put "import time";
			put "NUM_DHCHAINS = &num_dhchains.";
			put "prog_names = [fil for fil in os.listdir(os.getcwd()) if fil.endswith('.sas')]";
			put "prog_names = sorted(prog_names, key=lambda x: int(x.replace('.sas','').replace('&filename_prefix._','')))";
			put "chain_size = int(math.ceil(float(len(prog_names)) / float(NUM_DHCHAINS)))";
			put "def chunks(l, n):";
			put "    for i in xrange(0, len(l), n):";
			put "        yield l[i:i+n]";
			put "


			";

			put "chain_commands = ['dhchain -ts &_allmail. ' + ' '.join(l) for l in list(chunks(prog_names, chain_size))]";
			put "for command in chain_commands:";
			put "    os.system(command)";
			put "    time.sleep(&stagger.)";
		run;
		
		options NOQUOTELENMAX;
		* loop to wait until they are all done;
/*		%single_quote(all_new_progs, " ");*/
/*		%let rc=0;*/
/*		%put all new progs is: &all_new_progs.;*/
/*		%do %while(&rc.=0);*/
/**/
/*			* wait 2 minutes before checking;*/
/*			data _null_;*/
/*				slept = sleep(120000);*/
/*			run;*/
/*			*/
/*			* pipe in processes on the linux server and look for the file names;*/
/*			filename linux PIPE  'ps -eo command';*/
/*			libname sasdata "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/parallel_directory/";*/
/**/
/*			data print_dummy;*/
/*				infile linux firstobs=2 end=eof;*/
/**/
/*				length command $50 noterminal $50 program $1000;*/
/*				input command $ program;*/
/*				length progs_still_running 8.;*/
/*				retain progs_still_running;*/
/*				if _n_=1 then progs_still_running=0;*/
/*				if strip(program) in (&all_new_progs.) then progs_still_running=sum(progs_still_running,1);*/
/**/
/*				if eof and progs_still_running=0 then do;*/
/*					call symput("rc","1");*/
/*				end;*/
/*				list;*/
/*			run;*/
/*			*/
/*		%end;*/
/*		options QUOTELENMAX;*/

		* consolidate logs into the original programs log;
/*		options nosource nonotes noquotelenmax;*/
/*		%single_quote(all_new_logs, " ");*/
/*		%do j = 1 %to %sysfunc(countw(&param1.));*/
/**/
/*			%let thislog = %scan(&all_new_logs.,&j., %str( ));*/
/*			%let thissas = %scan(&all_new_progs.,&j., %str( ));*/
/**/
/*			%put -----------------------------------------------------------------------------------------------;*/
/*			%put ---BEGINNING OF LOG &thislog.---;*/
/*			%put -----------------------------------------------------------------------------------------------;*/
/*						data _null_;*/
/*							infile &thislog.;*/
/*							input @1 line $500.;*/
/*							put line;*/
/*						run;*/
/*			%put -----------------------------------------------------------------------------------------------;*/
/*			%put ---END OF LOG &thislog.---;*/
/*			%put -----------------------------------------------------------------------------------------------;*/
/**/
/*			%single_unquote(thislog, " ");*/
/*			%single_unquote(thissas, " ");*/
/**/
/*			%if %substr(%upcase(&cleanup.),1,1)=Y %then %do;*/
/*			x "rm &thislog.";*/
/*			x "rm &thissas.";*/
/*			%end;*/
/*		%end;*/
/*		options source notes quotelenmax;*/

	%mend _runpar;

	%mask_code(_runpar);

%mend parallel;
