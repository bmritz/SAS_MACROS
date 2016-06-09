* macro name: index_to;
* brian ritz;
* this macro will create a new column on a long dataset that is the index of all values to a specified row;

*parameters

data = input dataset
out - output dataset name
by - by group for analysis, you will get a different index for every by group
index_var - the variable which contains the value which serves as the base of the index, if there are >1 vars that specify the base, make them space delimited 
index_value - the values of index_var which mark that row to serve as the base for the indicies calculated within each by group, 
				if there are >1 vars that specify the base, specify one index_value in the same order as index_var separated by |, no quotes
index_var_name - the name of the new variable created that represents the index;


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


%macro index_to(data=, out=, by=, index_var=, index_value=, value_var=, index_var_name=);

* make a where clause to find the rows which will consist of the baseline for the index;

%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/format_macro_vars.sas";
%include "/kroger/Lev1/analysis/share/mi/analyst_toolkit/macros/data_vars_to_macro_vars.sas";

%let _num_vars = %getVar(%str(&data.),N);
%let _char_vars = %getVar(%str(&data.),C);

%let _where =;
%do i = 1 %to %sysfunc(countw(&index_var.)); 
	%let _this_var = %scan(&index_var., &i.);

	* if it is numeric then no quotes;
	%if %get_pos(&_this_var., &_num_vars.)>0 %then %do;
		%if &i. > 1 %then %let _where= &_where. and ;
		%let _where = &_where. %scan(&index_var.,&i.)=%scan(&index_value., &i., "|");
	%end;
	%else %if %get_pos(&_this_var., &_char_vars.)>0 %then %do;
		%if &i. > 1 %then %let _where= &_where. and ;
		%let _where = &_where. %scan(&index_var.,&i.)=%str(%')%scan(&index_value., &i., "|")%str(%'); 
	%end; ;
	
%end;
%let _where=%unquote(&_where.);
data _indicies;
	set &data.;
	where &_where.;
run;

proc sort data=_indicies(keep=&by. &value_var. rename=(&value_var.=_index_vvar));
	by &by.;
run;

proc sort data=&data. out=_d1;
	by &by.;
run;

data &out.(drop=_index_vvar rename=(index=&index_var_name.));
	length index 8.;
	merge _d1(in=a) _indicies(in=b);
	by &by.;
	index = &value_var. / _index_vvar * 100 ;
	if a then output;
run;

proc datasets lib=work;
	delete _d1 _indicies;
run;

%mend;
