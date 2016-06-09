* macro parallel;
* brian ritz;
* runs a bunch of macro calls simulataneously in different programs that the macro creates;
* the macros will all run with different parameters;
* you can specify two macro names, and the second macro name will run after all of the first macros are finished.;


%macro parallel(macro=,stagger=0,param1=,param2=,param3=,param4=,param5=, cleanup=Y, allmail=Y, num_dhchains=0);
	%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/mask_code.sas";
	* we put all of our code inside another macro and mask that macro...;
	* we do this so when the newly created programs include the original program, the parallel macro runs again but the code inside this runpar does not run again;
	* prevents never ending recursion;

	%macro _runpar;
		%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/format_macro_vars.sas";
		%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/get_filenames.sas";
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
		%put &original_sas_prog.;
		%let first_slash = %index(%sysfunc(reverse(&original_sas_prog.)),/);
		%let ln = %length(&original_sas_prog.);
		%let par_directory = %substr(&original_sas_prog.,1, %eval(&ln.-&first_slash.+1));
		%let new_dir = %QStrReplace(&original_sas_prog.,.sas,_parallel/);
		%let orig_prog_name = %QStrReplace(&original_sas_prog.,&par_directory.,%str());
		%let orig_prog_name = %QStrReplace(&orig_prog_name.,.sas,%str());

		%let maconly_prog = &new_dir.&orig_prog_name._macroonly.sas;
		%let driver_prog = &new_dir.&orig_prog_name._&macro._driver.py;

		* remove the directory if it is there and make a new one -- this makes sure an .os file is there;
		x "rm -r &new_dir.";
		x "mkdir &new_dir.";


		* create a sas file in the directory with only the macros from the original program -- called &maconly_prog.;
		x "python /kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/sandbox/parallel_20160225_helper.py &original_sas_prog. &maconly_prog.";


		*************** loop through each row param_dset file ;
		proc sql noprint;
			select count(*) into :_numrows from &param_dset.;
		quit;
		%single_quote(original_sas_prog, " ");
		%single_quote(maconly_prog, " ");

		%do i = 1 %to &_numrows.;

			* put the values for parameters into macro variable;
			data _NULL_;
				set sashelp.class(firstobs=&i. obs=&i.);
				array _n {*} _NUMERIC_;
				array _c {*} _CHARACTER_;
				length macro_params $10000;
				macro_params = "";
				do i = 1 to dim(_n);
					new_param = catx("=",vname(_n[i]),_n[i]);
					macro_params = catx(",", macro_params,new_param);
				end;
				do i = 1 to dim(_c);
					new_param = catx("=",vname(_c[i]),_c[i]);
					macro_params = catx(",", macro_params,new_param);
				end;
				call symputx("_macro_params", macro_params);
			run;

			%let macro_call=&macro.(&_allp.);

			***MAKE THE FILE;
			%let progname=&orig_prog_name._&macro._&i.;
			%let filname = &new_dir.&progname..sas;

			data _null_;
				length x $4000;
				file "&filname.";
				put "filename maconly &maconly_prog.;";
				put "%include maconly;";  * the call to parallel will be masked;
				x = "%"||"&macro_call."||";";
				x = strip(x);
				put x;
			run;
		
		%end;

		%if &allmail.=Y %then %do;
			%let _allmail = -allmail;
		%end;
		%else %do;
			%let _allmail=;
		%end;

		* make the driver program that will kick off all the programs we just created in the loop;
		data _null_;
			file "&driver_prog.";
			put "import os";
			put "import math";
			put "import time";
			put "os.chdir('&new_dir.')";
			put "NUM_DHCHAINS = &num_dhchains.";
			put "prog_names = [fil for fil in os.listdir(os.getcwd()) if fil.endswith('.sas') and fil != '&orig_prog_name._macroonly.sas']";
			put "prog_names = sorted(prog_names, key=lambda x: int(x.replace('.sas','').replace('&orig_prog_name._&macro._','')))";

			put "def chunks(l, n):";
			put "    for i in xrange(0, len(l), n):";
			put "        yield l[i:i+n]";
			put "


			";
			put "if NUM_DHCHAINS > 0:";
			put "    chain_size = int(math.ceil(float(len(prog_names)) / float(NUM_DHCHAINS)))";
			put "    chain_commands = ['dhchain -ts &_allmail. ' + ' '.join(l) for l in list(chunks(prog_names, chain_size))]";
			put "else:";
			put "    chain_commands = ['dhbatch ' + p for p in prog_names]";
			put "


			";
			put "for command in chain_commands:";
			put "    os.system(command)";
			put "    time.sleep(&stagger.)";
		run;
		
		x "python &driver_prog.";
		options NOQUOTELENMAX;

		* wait 2 minutes before checking;
		data _null_;
			slept = sleep(20000);
		run;

		* loop to wait until they are all done;
		* 1 find all sas programs that we kicked off;
		* 2 if we do not find a cooresponding .os file for that sas file, we assume it is complete;
		%let rc=0;

		* 1 find all .sas files;
		%get_filenames(location=&new_dir., out=_filenames);
		data _all_progs;
			set _filenames;
			where strip(upcase(substr(reverse(strip(filename)),1,4))) = "SAS." and upcase(strip(filename)) ne upcase("&orig_prog_name._macroonly.sas");
			filename = upcase(tranwrd(filename,".sas",""));
		run;

		* check for .os file every 2 minutes;
		%do %while(&rc.=0);

			* wait 2 minutes before checking;
			data _null_;
				slept = sleep(20000);
			run;

			%get_filenames(location=&new_dir., out=_filenames);
			
			data _still_running;
				set _filenames;
				where strip(upcase(substr(reverse(strip(filename)),1,3)))="SO.";
				filename = upcase(tranwrd(filename,".os",""));
			run;

			proc sort data= _still_running;
				by filename;
			run;
			proc sort data=_all_progs out=_all_progs;
				by filename;
			run;

			* all progs is a list of programs still running, if it is empty, we exit the loop;
			data _all_progs _finished;
				merge _all_progs(in=a) _still_running(in=b);
				by filename;
				if a and b then output _all_progs;
				if a and ~b then output _finished;
			run;

			* write to the log when a program finishes;
			data _null_;
				set _finished;
				put "The following program finished at &sysdate. &systime.:";
				put filename;
				put " ";
			run;

			%let _dsid = %sysfunc(open(_all_progs));
			* if there are no more obs in _all_progs, then exit;
			%if %sysfunc(attrn(&_dsid.,nobs)) = 0 %then %do;
				%let rc=1;
			%end;
			%let _not_needed = %sysfunc(close(&_dsid.));
		%end;

		proc datasets lib=work;
			delete _finished _all_progs: _still_running;
		run;

	%mend _runpar;

	%mask_code(_runpar);

%mend parallel;
