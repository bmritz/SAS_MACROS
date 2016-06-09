
** TODO: add ability to call with colons or - array names;
%macro append_multiple(dsets= ,out=, id=);
	* the purpose of this macro is to append all of the datasets specified by the dsets parameter together
		without losing information because of different variable lengths;

	* initialize the varlist -- we will append to this with the variables from every dataset except the first, which is used there to initialize;
	proc contents data=%scan(&dsets.,1, %str( )) out=varlist_final(keep=name length type);
	run;

	%let _num=2;
	%let _dsname=%scan(&dsets,&_num., %str( ));
	%do %while(&_dsname ne);
	  
		proc contents data=&_dsname. out=varlist1(keep=name length type rename=(type=type1 length=length1));
		run;

		proc sort data=varlist1; by name; run;
		proc sort data=varlist_final; by name; run;

		data varlist_final(keep= name length type);	
			merge varlist_final varlist1;
			by name;
			length = max(length, length1);
			if type ne type1 then do;
				put "WARNING: TYPES DO NOT MATCH UP";
				type = max(type, type1);
			end;
		run;

	  %let _num=%eval(&_num+1);
	  %let _dsname=%scan(&dsets,&_num, %str( ));
	%end;


	* make the length statement;
	%let _length_statement_char=;
	%let _length_statement_num=;
	proc sql;
		select name||" $"||put(length,5.-l) into : _length_statement_char separated by " " from varlist_final where type=2;
		select name||" "||strip(put(length,5.-l))||"." into : _length_statement_num separated by " " from varlist_final where type=1;
	quit;

	* format will be called in the data step so we know where each observation came from;
	proc format;
	value xxdset
		%do _i = 1 %to %sysfunc(countw(&dsets.));
			&_i. = "%scan(&dsets,&_i,%str( ))"
		%end;
		;
	run;

	* make a list of all datasets to set -- this loop adds the in=;
	%let _all_dsets=;
	%do _i = 1 %to %sysfunc(countw(&dsets.)); 
		%if (%scan(&dsets.,&_i,%str( )) ne ) %then %do;
		%let _all_dsets = &_all_dsets. %scan(&dsets.,&_i,%str( ))(in=ds_&_i.) ;
		%end;
	%end;

	data &out.;
		*length of id variable is 37 because possible 8 for libref + 1 for period + 28 for file name;
		length &_length_statement_char. &_length_statement_num. &id. $37 ;
		set &_all_dsets. ;

		%do _i = 1 %to %sysfunc(countw(&dsets.)); 
			%if (%scan(&dsets.,&_i,%str( )) ne ) %then %do;
				if ds_&_i. then &id.=put(&_i.,xxdset.);
			%end;
		%end;
	run;
		 		

	proc datasets lib=work;	
		delete varlist_final varlist1;
	run;
		
%mend;


%macro append_mulitiple_test;

data a;	set sashelp.class;run;

data b ;set sashelp.class;run;


%append_multiple(dsets = a b, out=test, id=whichdset);

%mend;

/*%append_mulitiple_test;*/
