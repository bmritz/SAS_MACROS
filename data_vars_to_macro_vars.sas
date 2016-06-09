* transforms data variable names into macro variable lists;



* TODO: ADD DATES;
* find binary variables -- they will not be transformed;
%macro data_vars_to_macro_vars(data=, var=_all_, character_name=%str(), numeric_name=%str(), binary_name=%str(), non_binary_numeric_name=%str(), obs=MAX);
%include "./list_macros.sas";

%if &character_name. ne %str() %then %do;
%global &character_name.;
%end;

%if &numeric_name. ne %str() %then %do;
%global &numeric_name.;
%end;

%if &binary_name. ne %str() %then %do;
%global &binary_name.;
%end;

%if &non_binary_numeric_name. ne %str() %then %do;
%global &non_binary_numeric_name.;
%end;

proc contents data=&data.(keep=&var.) out=_vnames noprint;
run;

data _null_;
  set _vnames end=EOF;
  length numerics characters $30000;
  retain numerics characters;
  if type = 1 then numerics=catx(" ", numerics, name);
  if type = 2 then characters = catx(" ", characters, name);
  
  if eof then do;
  %if &numeric_name. ne %str() %then %do;
    call symputx("&numeric_name.", numerics);
  %end;
  %if &character_name. ne %str() %then %do;
    call symputx("&character_name.", characters);
  %end;
  %if &binary_name. ne %str() or &non_binary_numeric_name. ne %str() %then %do;
    call symputx("_binary_dummy", numerics);
  %end;
  end;

run;

/*proc sql;*/
/*  %if &numeric_name. ne %str() %then %do;*/
/*    select name into : &numeric_name. separated by " " from _vnames where type=1;*/
/*  %end;*/
/*  %if &character_name. ne %str() %then %do;*/
/*    select name into : &character_name. separated by " " from _vnames where type=2;*/
/*  %end;*/
/*  %if &binary_name. ne %str() or &non_binary_numeric_name. ne %str() %then %do;*/
/*    select name into : binary_dummy separated by " " from _vnames where type=1;*/
/*  %end;*/
/*quit;*/

%if &binary_name. ne %str() or &non_binary_numeric_name. ne %str() %then %do;

  %if %sysfunc(countw(&_binary_dummy.)) > 0 %then %do;
    data _null_;
      set &data.(obs=&obs.) end=EOF;
      length bin_vars nonbin_vars $32000;
      array _n {*} &_binary_dummy.;
      array _flg {*} %suffix(b, &_binary_dummy.);
      retain _flg;
      if _n_ = 1 then do i = 1 to dim(_flg);
        _flg[i]=1;
      end;

      do i = 1 to dim(_n);
        if _flg[i] = 1 then do ;        
          if _n[i] ne . and _n[i] ne 0 and _n[i] ne 1 then _flg[i] = 0;
        end;
      end;

      bin_vars = "";
      nonbin_vars = "";
      if EOF then do;
        do i = 1 to dim(_flg);
          if _flg[i] = 1 then bin_vars = catx(" ", bin_vars, vname(_n[i]));
          else nonbin_vars = catx(" ", nonbin_vars, vname(_n[i]));
        end;
        %if &binary_name. ne %str() %then %do;
          call symput("&binary_name.", bin_vars);
        %end;
        %if &non_binary_numeric_name. ne %str() %then %do;
          call symput("&non_binary_numeric_name.", nonbin_vars);
        %end;
      end;
    run;
  %end;
  %else %let &binary_name. = %str();
%end;

proc datasets lib=work nolist;
  delete _vnames;
run;
%mend;

/*%data_vars_to_macro_vars(data=to_test,character_name= charvar, numeric_name=numvar, binary_name=binvar2);*/
/*%put &charvar.;*/
/*%put &numvar.;*/
/*%put &binvar2.;*/

/*
Purpose: return the list of variables in a data set
Examples:
    %put %getVar(%str(sashelp.class));
    %put %getVar(%str(sashelp.class),n);
    %put %getVar(%str(sashelp.class),N);
    %put %getVar(%str(sashelp.class),c);
    %put %getVar(%str(sashelp.class),C);
Credits:
    Source code by Arthur Carpenter, Storing and Using a List of Values in a Macro Variable
         http://www2.sas.com/proceedings/sugi30/028-30.pdf
    Authored by Michael Bramley
    Jiangtang Hu (2013, Jiangtanghu.com) adds variable type (N, C) options.
	
	
	updated in http://www.sascommunity.org/wiki/Macro_VarList
*/

%macro getVar(dset,type) ; 

   %local varlist ; 
    %let fid = %sysfunc(open(&dset)) ; 
    %if &fid %then %do ; 
        %do i=1 %to %sysfunc(attrn(&fid,nvars)) ; 
            %if %upcase(&type) = N %then %do;
                %if %sysfunc(vartype(&fid,&i)) = N %then
                    %let varlist= &varlist %sysfunc(varname(&fid,&i));
            %end;
            %else %if %upcase(&type) = C %then %do;
                %if %sysfunc(vartype(&fid,&i)) = C %then
                    %let varlist= &varlist %sysfunc(varname(&fid,&i));
            %end;
            %else
                %let varlist= &varlist %sysfunc(varname(&fid,&i)); 
        %end ; 
        %let fid = %sysfunc(close(&fid)) ; 
    %end ; 
    &varlist 
%mend getVar ;

%macro getType(dset,var) ; 

   %local _type ; 
    %let fid = %sysfunc(open(&dset)) ; 
    %if &fid %then %do ; 
        %do __i=1 %to %sysfunc(attrn(&fid,nvars)) ; 
			%if %upcase(%sysfunc(varname(&fid,&__i))) = %upcase(&var) %then 
				%let _type = %sysfunc(vartype(&fid,&__i));
		%end;
/*            %if %upcase(&type) = N %then %do;*/
/*                %if %sysfunc(vartype(&fid,&i)) = N %then*/
/*                    %let varlist= &varlist %sysfunc(varname(&fid,&i));*/
/*            %end;*/
/*            %else %if %upcase(&type) = C %then %do;*/
/*                %if %sysfunc(vartype(&fid,&i)) = C %then*/
/*                    %let varlist= &varlist %sysfunc(varname(&fid,&i));*/
/*            %end;*/
/*            %else*/
/*                %let varlist= &varlist %sysfunc(varname(&fid,&i)); */
/*        %end ; */
        %let fid = %sysfunc(close(&fid)) ; 
    %end ; 
    &_type. 
%mend getType ;
