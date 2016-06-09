* brian ritz 5/24/2016;
* this puts all of the .log and .lst files in <location> into a <archive_folder>;
* TODO: not sure how it will handle its own log file when batched;

%macro archive_logs(location=, archive_folder=);

%include "./get_filenames.sas";

%get_filenames(location=&location., out=_progs);

proc sql;
	select filename into : _to_arc separated by " " from -progs where lowcase(substr(reverse(strip(filename)),1,4)) in ("gol.","tsl.") order by filename;
quit;

x "mkdir &archive_folder.";

%do i = 1 %to %sysfunc(countw(&_to_arc.));
	%let _thisfil = %scan(&_to_arc.,&i.);

	x "mv &location/&_thisfil. &archive_folder.";
%end;

proc datasets lib=work;
	delete _progs;
run;

%mend;
