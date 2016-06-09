
%macro convert_numeric(data=, out=%str(), var=%str(), pre_screen=1000, null_chars="", length=8);
%put Convert Numeric Macro starting, the characters &null_chars. will be counted as null;
* pre process so we know number of variables;

%if &out.=%str() %then %do;
	%let out=&data.;
%end;
%put &out.;
%if &var. = %str() %then %do;
proc contents data=&data. out=_varnames;
run;

proc sql;
	select put(count(distinct name),3.-l) into : _num_char_vars from _varnames where type=2;
	select strip(name) into : _all_char_vars separated by " " from _varnames where type=2;
quit;

proc datasets lib=work;
delete _varnames;
run;
%end;
%else %do;
	%let _num_char_vars = %sysfunc(countw(&var.));
	%let _all_char_vars = &var.;
%end;
* pre screen first x obs for speed -- dont need to loop through a lot of variables if within the first x obs we know they are character;
data _null_(drop=is_char);
	set &data.(obs=&pre_screen.) end=EOF;
	length numeric_vars $32767;
	length num_numeric_vars 8.;
	length is_char 3.;
	array _char{&_num_char_vars.} &_all_char_vars.;
	array _num{&_num_char_vars.} 8. _num_1-_num_&_num_char_vars.;
	retain _char numeric_vars _num;

	* assume every character variable is a numeric var until we see it isnt;
	if _n_ = 1 then do i = 1 to dim(_char);
	_num[i]=0;
	end;

	do i = 1 to dim(_char);
		* if it is a character, flag its corresponding _num var as 1;
		is_char = missing(input(_char[i],??32.)) and strip(_char[i]) not in (&null_chars.);
		if is_char then do;
			_num[i]=1;
		end;
	end;

	* write macro variables of vars we need to possibly change to numeric -- ie no characters found within this short pre-screen;
	if EOF then do ;
		numeric_vars="";
		do i = 1 to dim(_num);
			if _num[i] = 0 then numeric_vars = catx(" ", strip(numeric_vars), upcase(vname(_char[i])));
/*			if _num[i] = 0 then num_numeric_vars = sum(num_numeric_vars,1);*/
		end;
		call symput("_vars_to_change", strip(numeric_vars));
		* rename vars in next data step will look like: _num1234=char_var1 _num1235=char_var2;
		call symputx("_rename_length", countw(numeric_vars)*10 + countc(strip(numeric_vars)," ","ivt"));
		call symputx("_num_vars_to_change", countw(numeric_vars));
	end;

run;
%put &_num_vars_to_change.;
data &out.(drop= _nnum_: drop_vars rename_vars i is_char);
	set &data. end=EOF;
	array _char{&_num_vars_to_change.} &_vars_to_change.;
	array _num{&_num_vars_to_change.} &length.. _num_1-_num_&_num_vars_to_change.;
	array _notnum{&_num_vars_to_change.} 3. _nnum_1-_nnum_&_num_vars_to_change.;

	length drop_vars rename_vars $&_rename_length.;
	retain _char _notnum;

	* assume every character variable is a numeric var until we see it isnt;
	* assume every character variable is a numeric var until we see it isnt;
	if _n_ = 1 then do i = 1 to dim(_char);
		_notnum[i]=0;
	end;

	do i = 1 to dim(_char);
		* if it is a character, flag its corresponding _num var as 1;
		* put in logic to ignore a list of values that would represent nulls;
		%if &var. ne %then %do;
		is_char = missing(input(_char[i],??32.)) and strip(_char[i]) not in (&null_chars.);
		if is_char then _notnum[i]=1;
		else _num[i] = input(_char[i],??32.);
		%end;
		%else %do;
			_num[i] = input(_char[i], ??32.);
		%end;

	end;

	* make macro variables for drop and rename statments in next data step;
	if EOF then do ;
		drop_vars="";
		do i = 1 to &_num_vars_to_change.;
			if _notnum[i] = 1 then do;
				drop_vars = catx(" ", strip(drop_vars), upcase(vname(_num[i])));
			end;
			if _notnum[i] = 0 then do;
				drop_vars = catx(" ", strip(drop_vars), upcase(vname(_char[i])));
				rename_vars = catx(" ", strip(rename_vars), cat(upcase(vname(_num[i])),"=",upcase(vname(_char[i]))));
			end;
		end;
		call symput("_vars_to_drop", strip(drop_vars));
		call symput("_rename_stmt", strip(rename_vars));
	end;
run;

* this is inefficient to run through the data step again but we have to do it because we dont know 
until the end of the previous data step which vars we will have to drop and rename;
data &out.(rename=(&_rename_stmt.));
	set &out.(drop=&_vars_to_drop.);
	format _num_1-_num_&_num_vars_to_change. best20.;
run;

%mend;
