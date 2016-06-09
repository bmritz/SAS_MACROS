
***********************************************************************************************************************************
***********************************************************************************************************************************
macro_name: 	mask_code
author:				Brian Ritz
purpose:			this macro allows a snippet of code to only be run when the script on which it is written is executed
              If the script on which it is written is imported, then the code will not run


mask_code(filename_keyword, macro1, ...)


filename_keyword -- this should be the name of the sas script where the macros are created -- the macros specified
										will only run when the root script that is running contains the filename_keyword

macro1 ...       -- these are a list of macros that will be executed if the script running matches the filename_keyword
                    you can have as many macros run as you want, they will run in the order specified
                    DO NOT INCLUDE THE PERCENT SIGN WHEN YOU ARE SPECIFYING MACROS


makes sas programs work like python programs if __name__=="__main__"

***********************************************************************************************************************************
***********************************************************************************************************************************
;

* the mask macro means that the code within the macro will only run when the root process is the program in which it was created;
* we have this so we can import this file, and not have all the code run;
* that way, we can import the file and get the information about the customers like the formats without running the whole program again;

/*%macro mask_code/PARMBUFF;*/
/**/
/*data _null_;*/
/*set sashelp.vextfl(where=(upcase(xpath) like '%.SAS'));*/
/*call symput('__filename_keyword', scan(xpath,-1,'/'));*/
/*run;*/
/*%put &__filename_keyword.;*/
/*%let __filename_keyword=%scan(&syspbuff., 1);*/
/*%let __n = 2;*/
/*%let __mname=%scan(&syspbuff., &__n.);*/
/*%put __mname;*/
/*%if %symexist(_SASPROGRAMFILE) %then %do;*/
/*	%let __check_eg = %INDEX(&_SASPROGRAMFILE, &__filename_keyword.) ne 0;*/
/*%end;*/
/*%else %let __check_eg = 0;*/
/**/
/*%let __check_sas = %INDEX(&SYSPROCESSNAME., &__filename_keyword.) ne 0;*/
/**/
/*%if &__check_sas. or &__check_eg. %then %do;*/
/*	%do %while(&__mname. ne);*/
/*	*/
/*	%&__mname;*/
/**/
/*	%let __n=%eval(&__n.+1);*/
/*	%let __mname=%scan(&syspbuff., &__n.);*/
/*	%end;*/
/*%end;*/
/**/
/*%mend;*/

%macro mask_code/PARMBUFF;


data _null_;
	set sashelp.vextfl(where=(upcase(xpath) like '%.SAS'));
	if index(upcase(xpath), "KROGER_AUTOEXEC") = 0 then call symput('__filename_keyword', scan(xpath,-1,'/'));
run;

%let syspbuff2 = %sysfunc(translate(   &syspbuff.,  %str(  ), %str(%(%))    ));

%let __n = 1;
%let __mname=%scan(%quote(&syspbuff2.), &__n., %str(,));

* if we are in eg and no filename keyword was made, then we know we are in the original program because sas wont create the filename keyword with the program;
%if %symexist(_SASPROGRAMFILE) and %symexist(__filename_keyword) %then %do;
	%let __check_eg = %INDEX(&_SASPROGRAMFILE, &__filename_keyword.) ne 0;
%end;
%else %if %symexist(__filename_keyword)=0 %then %do;
	%let __check_eg=1;
%end;
%else %do;
	%let __check_eg = 0;
%end;

%let __check_sas = %INDEX(&SYSPROCESSNAME., &__filename_keyword.) ne 0;

%if &__check_sas. or &__check_eg. %then %do;
	%do %while(&__mname. ne);
	
	%&__mname;

	%let __n=%eval(&__n.+1);
	%let __mname=%scan(%quote(&syspbuff2.), &__n., %str(,));
	%end;
%end;
%else %do;
	%put NOTE (mask_code macro): The following macros from the mask code were not run because the program was masked:;
	%put NOTE (mask_code macro): &syspbuff2.;
%end;
%mend;
