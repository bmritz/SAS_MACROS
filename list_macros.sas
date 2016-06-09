%macro words(str,delim=%str( ));
  %local i;
  %let i=1;
  %do %while(%length(%qscan(&str,&i,&delim)) GT 0);
    %let i=%eval(&i + 1);
  %end;
%eval(&i - 1)
%mend words;

%macro nodup(list,casesens=no);

  %local i j match item errflag err;
  %let err=ERR%str(OR);
  %let errflag=0;
  %if not %length(&casesens) %then %let casesens=no;
  %let casesens=%upcase(%substr(&casesens,1,1));

  %if not %index(YN,&casesens) %then %do;
    %put &err: (nodup) casesens must be set to yes or no;
    %let errflag=1;
  %end;

  %if &errflag %then %goto exit;

  %do i=1 %to %words(&list);
    %let item=%scan(&list,&i,%str( ));
    %let match=NO;
    %if &i LT %words(&list) %then %do;
      %do j=%eval(&i+1) %to %words(&list);
        %if &casesens EQ Y %then %do;
          %if "&item" EQ "%scan(&list,&j,%str( ))" %then %let match=YES;
        %end;
        %else %do;
          %if "%upcase(&item)" EQ "%upcase(%scan(&list,&j,%str( )))" %then %let match=YES;
        %end;
      %end;
    %end;
    %if &match EQ NO %then &item;
  %end;

  %goto skip;
  %exit: %put &err: (nodup) Leaving macro due to problem(s) listed;
  %skip:

%mend nodup;

%macro prefix(prefix,list);
  %local i bit;
  %let i=1;
  %let bit=%sysfunc(scanq(&list,&i,%str( )));
  %do %while(%length(&bit));
&prefix.&bit
    %let i=%eval(&i+1);
    %let bit=%sysfunc(scanq(&list,&i,%str( )));
  %end;
%mend prefix;

%macro suffix(suffix,list);
  %local i bit;
  %let i=1;
  %let bit=%sysfunc(scanq(&list,&i,%str( )));
  %do %while(%length(&bit));
&bit.&suffix
    %let i=%eval(&i+1);
    %let bit=%sysfunc(scanq(&list,&i,%str( )));
  %end;
%mend suffix;
