***********************************************************************************************************************************
***********************************************************************************************************************************
module_name: 	format_macro_vars
author:				Brian Ritz
purpose:			This module contains macros that streamline working with macro variables containing dates and lists (such as lists of products, commodities, divisions, etc...)

List of useable macros in this module (there are a couple support macros also in this module whose sole purpose is to support the useable macros):

%single_unquote(invar, delim) -- 																	removes single quotes from a list contained in the macro variable &invar, 
																																	and delimits the list by &delim.

%single_quote(invar, delim) -- 																		adds single quotes to a list contained in the macro variable &invar, 
																																	and delimits the list by &delim

%get_today(varname,quote = Y) --                                  returns todays date in YYYYMMDD format to a macro variable called &varname

%kroger_week(date, varname, informat=YYMMDD8., quote=Y, pxy=) -- 	returns the kroger week of the &date(specified in YYYYMMDD form as default) to a macro variable called &varname

%current_kroger_week(varname, quote=Y, pxy=) --										returns the latest kroger week in the database to a macro variable called &varname

%kroger_week_math(kwk, diff, varname, quote=Y, pxy=) -- 					returns the kroger week &diff weeks away from &kwk to a macro variable called &varname

%date_math(date, diff, varname, quote=Y, pxy=) -- 								returns the date in YYYYMMDD form &diff days away from &date (also in YYYYMMDD form) 
																																	to a macro variable called &varname 

%latest_x_weeks(x, beg_varname, end_varname, quote=Y, pxy=) -- 		returns two macro variables (named &beg_varname and &end_varname) 
																																	that represent the start week and end week of the last &x weeks in the kroger database

%YYYYMMDD(krog_wk, newvar, day=1, quote=Y, pxy=) -- 							returns the date in YYYYMMDD form of the kroger week specifiec in &krog_wk. to a 
																																	macro variable called &newvar

%MMDDYYYY(krog_wk, newvar, day=1, quote=Y, pxy=) --											returns the date in MMDDYYYY form of the kroger week specifiec in &krog_wk. to a 
																																	macro variable called &newvar

%MMDDYY(krog_wk, newvar, day=1, quote=Y, pxy=)	--												returns the date in MMDDYY form of the kroger week specifiec in &krog_wk. to a 
																																	macro variable called &newvar

%current_date(varname, format=MMDDYYN8., quote=Y, pxy=)  					returns the latest date available in the kroger TRANSACTION database to a macro variable called &varname
																																	format is a sas data format (see http://support.sas.com/documentation/cdl/en/etsug/60372/HTML/default/viewer.htm#etsug_intervals_sect010.htm) 

%get_pos(word, list)						return the position of word in list, returns 0 if word not found in list -- list should be space delimited

%combine_lists(list1, list2) 				return all combinations of elements from each list separated by a _ -- primarily used to set up multidimensional arrays in data steps
***********************************************************************************************************************************
***********************************************************************************************************************************
;

%macro format_macro_vars_help;

option NOQUOTELENMAX;

data _null_;

title "FORMAT MACRO VARS SAS MACRO COLLECTION";
title2 "Help Documentation";
file print ;
put 
"module_name:	format_macro_vars"/
"author:		Brian Ritz"/
"purpose:	This module contains macros that streamline working with macro variables containing dates and lists"/
"		(such as lists of products, commodities, divisions, etc...)"///
"USE"/
"---"/
"There are a lot of macros in this module. This help documentation will list them out and specify the relevant parameters for each."/
"These macros can be used when handling macro variables in SAS. I found that they particularly come in handy when interfacing between SAS and SQL--like when 
things need to be single quoted or dates need to be in a certain format for instance."///
"OPTIONAL PARAMETERS"/
"-------------------"/
"Many of these macros have the two optional named parameters of quote= and pxy=. Their defaults are quote=Y and pxy=."/
"If the quote parameter is set to Y, the output macro variable will be output with single quotes around the macro variable value."/
"pxy= specifies a proxy user to be used for the macro. If none is given, it will use the proxy user from the last %db_proxy_user() call. If that macro was not previously called, the macro will error."

_BLANKPAGE_
"MACRO LIST"/
"----------"/
"single_quote(invar, delim)"/
"			-- adds single quotes to a list contained in the macro variable invar, and delimits the list by  delim."/
"			(invar is the name of the macro variable that contains the list)"///

"single_unquote(invar, delim)"/
"			-- removes single quotes from a list contained in the macro variable  invar, and delimits the list by  delim."/
"			(invar is the name of the macro variable that contains the list)"///

"get_today(varname,quote = Y)"/
"			-- returns todays date in YYYYMMDD format to a macro variable called  varname"///

"kroger_week(date, varname, informat=YYMMDD8., quote=Y, pxy=)"/
"			-- returns the kroger week of the  date(specified in YYYYMMDD form as default) to a macro variable called  varname"///

"current_kroger_week(varname, quote=Y, pxy=)"/
"			-- returns the latest kroger week in the database to a macro variable called  varname"///

"kroger_week_math(kwk, diff, varname, quote=Y, pxy=)"
"			-- returns the kroger week  diff weeks away from  kwk to a macro variable called  varname"///

"date_math(date, diff, varname, quote=Y, pxy=)"/
"			-- returns the date in YYYYMMDD form  diff days away from  date (also in YYYYMMDD form) to a macro variable called  varname "///


"latest_x_weeks(x, beg_varname, end_varname, quote=Y, pxy=)"/
"			-- returns two macro variables (named  beg_varname and  end_varname)"/
"			that represent the start week and end week of the last  x weeks in the kroger database"///

"YYYYMMDD(krog_wk, newvar, day=1, quote=Y, pxy=)"/
"			-- returns the date in YYYYMMDD form of the kroger week specifiec in  krog_wk. to a macro variable called  newvar"///

"MMDDYYYY(krog_wk, newvar, quote=Y, pxy=)"/
"			-- returns the date in MMDDYYYY form of the kroger week specifiec in  krog_wk. to a macro variable called  newvar"///

"MMDDYY(krog_wk, newvar, quote=Y, pxy=)"/
"			-- returns the date in MMDDYY form of the kroger week specifiec in  krog_wk. to a macro variable called  newvar"///

"current_date(varname, format=YYMMDDN8., quote=Y, pxy=)"
"			-- returns the latest date available in the kroger transactions table to a macro variable called  varname"/
"			Format is a sas data format (see http://support.sas.com/documentation/cdl/en/etsug/60372/HTML/default/viewer.htm#etsug_intervals_sect010.htm)"/
"			May take a few minutes -- be patient..."


;
run;
option QUOTELENMAX;


%mend;

*NOW THE ACTUAL MACRO;

*flag to tell other programs that this module was already imported...you can look for this flag in other programs to determine if you must include this module or not;
%let format_macro_vars_flag=Y;

*remove the single quotes around a list of things in a macro variable, again, you can specify your delimiter;
%macro single_unquote(invar,delim);


*change any double quotes to single quotes;
%let &invar. = %sysfunc(translate(%quote(&&&invar..),%str(%'),%str(%")));

data _null_;
	format var $char5000.0;
	retain var;
	do i = 1 to countw("&&&invar."," ,");
		var = catx(&delim.,var,compress(scan("&&&invar.",i," ,"),"'"));
	end;
	call symput("&invar.",strip(var));
run;


%mend;




*put single quotes around multiple things;
*specify any delimiter;
%macro single_quote(invar,delim);


%single_unquote(&invar.," ");
*change any double quotes to single quotes;
%let &invar. = %sysfunc(translate(%quote(&&&invar..),%str(%'),%str(%")));

data _null_;
	format var $char5000.0;
	retain var;
	do i = 1 to countw("&&&invar."," ,");
		var = catx(&delim.,var,cat("'",scan("&&&invar.",i," ,"),"'"));
	end;
	call symput("&invar.",strip(var));
run;


%mend;






%macro get_today(varname,quote = Y);
%global &varname.;
	data _null_;
		call symput("&varname.", put(today(),YYMMDDN8.));
	run;
	%if %upcase(%substr(&quote.,1,1))=Y %then %do;
		%single_quote(&varname.," ");
	%end;


%mend;






%macro check_proxy(_proxy_);
	%if &_proxy_. ne %str() %then %do;
		%db_proxy_user(&_proxy_.);
	%end;
	%else %do;
		%if %SYMEXIST(__SET_DB_PROXY_USER)=0 %then %do;
			%put ERROR: YOU MUST SPECIFY A PROXY USER FOR EXADATA;
			%abort;
		%end;
		%put The proxy from db_proxy_user call was used.;
	%end;


%mend;


*gets the kroger week of a date in MMDDYYYY form;
%macro kroger_week(date, varname, informat=YYMMDD8., quote=Y, pxy=);

%check_proxy(&pxy.);


* get the kroger week of the start date and the end date -- we first have to get a date -> kroger week mapping from exadata;
%dset_from_db(
	dset=x_kroger_week,
	sql = %str(select fis_week_id, date_id from date_dim order by date_id),
	sql_in_file=N
);

%if %sysfunc(countw(&date.))=%sysfunc(countw(&varname.)) %then %do X_i = 1 %to %sysfunc(countw(&varname.));
	%let _thisdate = %scan(&date., &X_i.);
	%let _thisvnam = %scan(&varname., &X_i.);

	%global &_thisvnam.;

	data _null_;
		set x_kroger_week;
		if datepart(date_id)=input("&_thisdate.", &informat.) then call symputx("&_thisvnam.", strip(put(fis_week_id,8.)));
	run;

	
	%if %upcase(%substr(&quote.,1,1))=Y %then %do;
		%single_quote(&_thisvnam.," ");
	%end;

%end;

proc delete data=x_kroger_week;
run;

%mend;


*gets the current kroger week from exadata;
%macro current_kroger_week(varname, quote=Y, pxy=);


%check_proxy(&pxy.);


%global &varname.;
%dset_from_db(

	dset=x_cur_kroger_wk,
	sql = %str(select fis_week_id from date_dim a inner join (SELECT MAX(Date_Id) as date_id FROM Warehouse.Seg_Type_Run_Date_Fct) b on a.date_id=b.date_id),
	sql_in_file=N

);

proc sql noprint;
	select fis_week_id into : &varname. from x_cur_kroger_wk;
quit;

%if %upcase(%substr(&quote.,1,1))=Y %then %do;
	%single_quote(&varname.," ");
%end;

proc delete data=x_cur_kroger_wk;
run;

	***;
%mend;



%macro kroger_week_math(kwk, diff, varname, quote=Y, pxy=);

	%check_proxy(&pxy.);

	%global &varname.;

	%dset_from_db(
		dset=x_kwks,
		sql=%str(select distinct fis_week_id from date_dim order by fis_week_id),
		sql_in_file=N
	);


	%if &diff.<0 %then %do;
		proc sort data=x_kwks;
			by descending fis_week_id;
		run;
	%end;
	%else %if &diff.>0 %then %do;
		proc sort data=x_kwks;
			by fis_week_id;
		run;
	%end;
	%else %do;
		%let &varname.=&kwk.;
		%return;
	%end;

	%single_unquote(kwk," ");
	%single_unquote(varname," ");


	data _null_;
		set x_kwks;
		retain weekno;
		if fis_week_id = &kwk. then do;
			weekno=1;
		end;

		if weekno > 0 and fis_week_id ne &kwk. then weekno=sum(weekno,1);

		if weekno = abs(&diff.) then call symputx("&varname.", strip(put(fis_week_id,8.)));

	run;

	%if %upcase(%substr(&quote.,1,1))=Y %then %do;
		%single_quote(&varname.," ");
	%end;

	proc delete data=x_kwks;
	run;
	
	***;
%mend;

* creates a macro variable that is _x_diff days away from the macro varaible given in _x_date which is assumed to be in MMDDYYYY form;
%macro date_math(_x_date, _x_diff, _x_varname, quote=Y, pxy=);
	%global &_x_varname.;

	%check_proxy(&pxy.);

	data _null_;
		call symput("&_x_varname.", put(input("&_x_date.",YYMMDD8.) + &_x_diff.,  YYMMDDN8.));
	run;

	%if %upcase(%substr(&quote.,1,1))=Y %then %do;
		%single_quote(&_x_varname.," ");
	%end;

	
	***;
%mend;

* creates two macro variables that represent the latest x weeks in our data solution;
%macro latest_x_weeks(x_x, beg_varname, end_varname, quote=Y, pxy=);

	%global &beg_varname.;
	%global &end_varname.;

	%current_kroger_week(&end_varname.,pxy=&pxy., quote=N);

	%if &x_x. < 0 %then %do;
		%let x_x = %eval(-1*&x_x.);
	%end;

	%kroger_week_math(&&&end_varname..,-&x_x., &beg_varname., pxy=&pxy., quote=N);

	%if %upcase(%substr(&quote.,1,1))=Y %then %do;
		%single_quote(&beg_varname.," ");
		%single_quote(&end_varname.," ");
	%end;

	
%mend;

*formats a kroger fis week as a date and puts it into another macro variable;
%macro YYYYMMDD(krog_wk, newvar, day=1, quote=Y, pxy=);


	%check_proxy(&pxy.);



	%global &newvar.;

	%dset_from_db(
	dset=x_dates, 

	sql = %str(
					select distinct fis_week_id
						,date_id
						,fis_day_of_week_num

					from date_dim
	        order by fis_week_id
						)

	, sql_in_file = N
	);

	%if %sysfunc(substr(&quote,1,1))= Y  %then %do;
	data _null_;
		set x_dates;
		if fis_week_id = "&krog_wk." and fis_day_of_week_num = &day. then call symput("&newvar.", cat("'",put(datepart(date_id),YYMMDDN8.),"'"));
	run;
	%end;
	%else %do;
	data _null_;
		set x_dates;
		if fis_week_id = "&krog_wk." and fis_day_of_week_num = &day. then call symput("&newvar.", put(datepart(date_id),YYMMDDN8.));
	run;
	%end;

	proc datasets library=work nolist;
		delete x_dates;
	run;

	***;
%mend;






*formats a kroger fis week;
%macro MMDDYYYY(krog_wk, newvar, day=1, quote=Y, pxy=);


	%check_proxy(&pxy.);


%global &newvar.;

%dset_from_db(
dset=x_dates, 

sql = %str(
				select distinct fis_week_id
					,date_id
					,fis_day_of_week_num

				from date_dim
        order by fis_week_id
					)

, sql_in_file = N
);


	%if %sysfunc(substr(&quote,1,1))= Y  %then %do;
	data _null_;
		set x_dates;
		if fis_week_id = "&krog_wk." and fis_day_of_week_num = &day. then call symput("&newvar.", cat("'",put(datepart(date_id),MMDDYYN8.),"'"));
	run;
	%end;
	%else %do;
	data _null_;
		set x_dates;
		if fis_week_id = "&krog_wk." and fis_day_of_week_num = &day. then call symput("&newvar.", put(datepart(date_id),MMDDYYN8.));
	run;
	%end;

	proc datasets lib=work nolist;
		delete x_dates;
	run;


	***;
%mend;



*formats a kroger fis week;
%macro MMDDYY(krog_wk, newvar, day=1, quote=Y, pxy=);


	%check_proxy(&pxy.);

	%global &newvar.;

	%dset_from_db(
	dset=_dates, 

	sql = %str(
					select distinct fis_week_id
						,date_id
						,fis_day_of_week_num

					from date_dim
	        order by fis_week_id
						)

	, sql_in_file = N
	);

	%if %sysfunc(substr(&quote,1,1))= Y  %then %do;
	data _null_;
		set _dates;
		if fis_week_id = "&krog_wk." and fis_day_of_week_num = &day. then call symput("&newvar.", cat("'",put(datepart(date_id),MMDDYYN6.),"'"));
	run;
	%end;
	%else %do;
	data _null_;
		set _dates;
		if fis_week_id = "&krog_wk." and fis_day_of_week_num = &day. then call symput("&newvar.", put(datepart(date_id),MMDDYYN6.));
	run;
	%end;
	
	proc datasets lib=work nolist;
		delete _dates;
	run;

	***;
%mend;


%macro current_date(varname, format=YYMMDDN8., quote=Y, pxy=);

%db_proxy_user(an_mp_ws06);
%check_proxy(&pxy.);

* where clause to make it go faster;
%global &varname.;
%dset_from_db(

	dset=x_cur_kroger_date_trans,
	sql = %str(select max(date_id) as date_id from transaction_basket_fct where date_id > (select max(date_id) as date_id FROM Warehouse.Seg_Type_Run_Date_Fct)),
	sql_in_file=N

);

proc sql noprint;
	select put(datepart(date_id), &format.) into : &varname. from x_cur_kroger_date_trans;
quit;

%if %upcase(%substr(&quote.,1,1))=Y %then %do;
	%single_quote(&varname.," ");
%end;

proc delete data=x_cur_kroger_date_trans;
run;

***;
%mend;



%macro get_pos(word, list);
%let list2 = %str( )&list.%str( );
%let word2 = %str( )&word.%str( );
%let list2 = %upcase(&list2.);
%let word2 = %upcase(&word2.);
%if %index(&list2.,&word2.) > 0 %then %do;
%let list_pos=%sysfunc(countw(%substr(&list2.,1,%index(&list2.,&word2.)+1))); 
&list_pos.
%end;

%else %do;
0
%end;
%mend;

		
%Macro QStrReplace(In_what,From_what,To_what);
%*
  20141003, SB: Name changed to QStrReplace. Bquote added.
                Unwanted side-effects: Input string is unquoted.
  20140921, SB: First version

  Source: http://www.sascommunity.org/wiki/SAS/Macro_String_Replace_Function
          Copyright (c) 2008 Paul Oldenkamp, GNU License
;
%Local s Pos_fw L_str R_str;
  %Let s=&In_what;
  %Do %While(%index(&s,&From_what) > 0);
    %Let Pos_fw=%index(&s,&From_what);
    %If &Pos_fw > 0 %then %do;
	  %if &pos_fw. > 1 %then %do;
	      %Let L_str=%Bquote(%substr(&s,1,%eval(&Pos_fw - 1)));
	  %end;
	  %else %do;
		  %Let L_str=%Bquote();
	  %end;
	  %if %eval(&Pos_fw. + %length(&From_what.)) <= %length(&s.) %then %do;
	      	%Let R_str=%Bquote(%substr(&s,%eval(&Pos_fw + %length(&From_what))));
	  %end;
	  %else %do;
			%Let R_str=%BQuote();
	  %end;
      %Let s=%Unquote(&L_str&To_what&R_str);
      %End;
  %End;
  &s
%Mend QStrReplace;

* gives every combination of two lists;
%macro combine_lists(list1, list2, initialize_zeros=N);
%let _out = ;
%let _zeros=( ;
%do i = 1 %to %sysfunc(countw(&list1.));
	%let w1=%scan(&list1.,&i.);
	%do j = 1 %to %sysfunc(countw(&list2.));
		%let w2 = %scan(&list2.,&j.);
		
		%let _out=&_out. %trim(&w1.)_%trim(&w2.);
		%let _zeros=&_zeros. 0;

		%if (&i. ne %sysfunc(countw(&list1.))) and (&j. ne %sysfunc(countw(&list2.))) %then %let _zeros=&_zeros.,;
	%end;
%end;

%if &initialize_zeros. = Y %then %do;
&_out. &_zeros.)
%end;
%else %do;
&_out.
%end;
%mend;
