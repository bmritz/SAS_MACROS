

%macro get_filenames(location=, out=);
filename _dir_ "%bquote(&location.)";
data &out.(keep=filename);
  handle=dopen( '_dir_' );
  if handle > 0 then do;
    count=dnum(handle);
    do i=1 to count;
      filename=dread(handle,i);
      output &out.;
    end;
  end;
  rc=dclose(handle);
run;
filename _dir_ clear;
%mend;
