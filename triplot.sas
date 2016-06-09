/***********************************************************/
/* Plotting tool which separates plots into various files  */
/* by mean point r-squared.                                */
/* Clayton Beck                                  10/14/02  */
/***********************************************************/

%macro triplot(data, targetv, targtype, groups, rsqcut, pcut, specify, vars, mmiss);

/*** Create macro vars that will be used to split the output into three different files ***/

*options mprint mlogic macrogen;
options msglevel=N nonotes;

data _NULL_;
	t0 = "&sysparm";		/*title macro variable*/       							  
	t1 = index(t0, '/');	/*find location of first slash*/
	t2 = length(t0); 		/*get length of title macro variable*/
	t3 = t2 - t1 + 1;		/*calculate length from first slash to end*/
	t4 = substr (t0,t1,t3);	/*save stuff from first slash on*/
	t5 = t3 - 3;			/*calculate position of potential .sas*/
	if substr (t4, t5, 4) = '.sas' then t4 = substr (t4, 1 , t5-1); /*if last four char are .sas then rm*/

	bad = compress ( t4 || '-bad.lst');
	good = compress ( t4 || '-good.lst');
	bad2 = compress ( t4 || '-bad.lst');
	good2 = compress ( t4 || '-good.lst');

	call symput('badfile', trim(bad) );
	call symput('goodfile', trim(good) );
	call symput('badlog', trim(bad2) );
	call symput('goodlog', trim(good2) );
run;

/*** Prep the files ***/

/*proc printto log="&badlog" print="&badfile" ;
run;
proc printto log="&goodlog" print="&goodfile" ;
run;
proc printto log=log print=print ;
run;*/

/*** Create macro vars for the lables, var names, and the # of independent vars ***/

data einc (keep=vnam labe );
	set &data (obs=1 &specify=&vars);
	array transf(*) _NUMERIC_;
	length labe $ 60;
	length vnam $ 40;
	do I = 1 to dim(transf);
			call vname (transf(I),vnam);
			call label (transf(I),labe);
			output;
	end;
run;

data _NULL_;
	set einc end=eof;
	call symput ('vnam'||left(_N_),trim(vnam));
	call symput ('lab'||left(_N_),labe);
	if eof then call symput('J', left(_N_));
run;

/*** Begin the do loop to analyze each variable ***/

%do i = 1 %to &J;

/*** Group the independent vars into ntiles ***/

data zweic;
	set &data (keep=&&vnam&i &targetv);
	if &&vnam&i = &mmiss then do;
		&&vnam&i = .a;    /*** SPECIAL MISSING VALUE, DISTINCT FROM . ***/
	end;

	proc rank data=zweic groups=&groups out=zweic(keep=rindep &&vnam&i &targetv);
		var &&vnam&i;
		ranks rindep;

/*** Get Overall min and max of independent variable ***/

proc means data=&data noprint;
	var &&vnam&i;
	output out=zweic2 min=low max=top;

/*** Get min and max of mean points for independent variable ***/

proc means data = zweic noprint;
	class rindep;
	var &&vnam&i;
	output out=missfix(where=(rindep ne .)) mean(&&vnam&i) = missmean;

proc means data = missfix noprint;
	var missmean;
	output out=missfix mean(missmean)=mmean min(missmean)=mmin;

/*** Put back in special value and adjust ranks accordingly ***/

data dreic;
	if _N_ = 1 then set missfix;
	set zweic;

	if &&vnam&i = .a then do;
		rindep = 0;
		&&vnam&i = &mmiss;
	end;
		else if &&vnam&i = . then do;
			rindep = -1;
			&&vnam&i = mmin - (mmean - mmin)/5;
		end;
			else do;
				rindep = rindep + 1;
			end;

/*** Get means by these ranks ***/

proc means data = dreic noprint;
	class rindep;
	var &&vnam&i &targetv ;
	output out=zweic(where=(rindep ne .)) n(&&vnam&i)=weight 
		   mean(&targetv)=mndepend mean(&&vnam&i)=mnindep;

/*** Get Correlations of means of ranks ***/

data zweic;
	if _n_ = 1 then set zweic2 (keep=top low);
	set zweic;
	if low=0 and top=1 then do;
		lgmn = log(mnindep+0.01);
		sqmn = sqrt(mnindep);
		invmn = 1 / (mnindep + 0.01);
		offset = 0.01;
	end;
	else if low=0 then do;
		lgmn = log(mnindep+1);
		sqmn = sqrt(mnindep);
		invmn = 1 / (mnindep+1);
		offset = 1;
	end;
	else if low<0 then do;
		lgmn = log(mnindep - low + 1);
		sqmn = sqrt(mnindep - low);
		invmn = 1 / (mnindep - low + 1);
		offset = -low + 1;
	end;
	else do;
		lgmn = log(mnindep);
		sqmn = sqrt(mnindep);
		invmn = 1 / (mnindep);
		offset = 0;
	end;

call symput ('offs', left(offset));

if rindep ne -1 then symbol = 'A';
	else do;
		symbol = 'M';
		mnote = '* Missing Values Plotted at Point M *';
	end;

if mndepend = 0 and _freq_ > 500 then flag = '***** Mean of Target is 0 *****';
	else if mndepend = 1 and _freq_ > 500 then flag = '***** Mean of Target is 1 *****';
else flag = '  ';

proc corr data = zweic noprint outp=fierc(where=(_TYPE_='CORR'));
 	var mnindep lgmn sqmn invmn;
	with mndepend;
	weight weight;

data _NULL_;
	set fierc;
	array listv(4) mnindep lgmn sqmn invmn; 
	array listv2(4) $ mn2 lgmn2 sqmn2 invmn2;
	do k=1 to 4;
	listv(k) = listv(k) * listv(k);
	listv2(k) = put(listv(k), z6.4);
    end;
	if mn2 ge &rsqcut then good = 1;
	else good = 0;

	call symput ('isgood',good);
	call symput ('rsquare',mn2);
	call symput ('lrsquare',lgmn2);
	call symput ('srsquare',sqmn2);
	call symput ('irsquare',invmn2);
	run;
run;

/*** If variable passes rsq cut then output to good data list
				and plot in good listing ***/

%if &isgood = 1 %then %do;
	/*proc printto log="&goodlog" print="&goodfile";*/

data new;
	file log ps=500;
		length name $ 40;
		name = "&&vnam&i";
		put name;

/*** Print the Means and N ***/

options ps=20;

data tpzweic;
	set zweic;
	if rindep = -1 then mnindep = .;

		proc print noobs data = tpzweic split='*';
		 	var rindep _freq_ mnindep mndepend mnote flag;
			label _freq_ = 'N'
			rindep = "Rank"
			flag = 'Notes'
			mnote = 'Missing'
			mndepend = "Mean of*&targetv"
			mnindep = "Mean of*&&vnam&i";
		title2 "Plot and Means of &&vnam&i and &targetv by rankings - &&vnam&i is &&lab&i";
		where rindep ne .;
		footnote ' ';

run;

/*** Run the plot ***/

options ps=50;

proc plot data = zweic hpercent=90 vpercent=75 nolegend;
	plot mndepend*mnindep =symbol;
label mndepend = "&targetv" 
	  mnindep = "Variable &&vnam&i: &&lab&i";
title2 "&groups Point Means Plot of &targetv with &&vnam&i - &&lab&i";
title3 "&groups Mean Points R-Squared is &rsquare Log=&lrsquare SquareRoot=&srsquare Inverse=&irsquare Offset Used for log,inverse=&offs";
where rindep ne .;

/*** finish processing good r-squared variables ***/

 %end;

/*** If variable fails rsqcut then calculate additional measure ***/

 %else  %do;
 	%if "&targtype" = "b" or "&targtype" = "B" or "&targtype" = "Binary" or "&targtype" = "binary"
                          or "&targtype" = "bin" or "&targtype" = "bi" or "&targtype" = "Bin"
                          or "&targtype" = "Bi" or "&targtype" = "01" %then %do;

			proc freq data=dreic noprint;
				tables &targetv * rindep / chisq  ;
				output out = chis(keep=P_PCHI) chisq;

			data chis;
				set chis;
				x = max (P_PCHI, 0.000001);
				y = put(x, z8.6);
				call symput ('pvalue', y);
			run;

			%let later =Chi-square pvalue is;
				%end;

				%else %do;

				proc glm data=dreic noprint outstat=chis(keep=PROB _TYPE_);
					class rindep;
					model &targetv = rindep;

			data chis;
				set chis;
				where _TYPE_ = 'SS1';
				x = max (PROB , 0.000001);
				y = put(x, z8.6);
				call symput ('pvalue', y);
			run;

			%let later =Anova pvalue is;

			%end;

/*** If variable fails pcut then output to bad data list ***/

%if %substr(&pcut,1,1) =. %then %let pcut = 0&pcut;                                  

%if  &pvalue ge &pcut  %then %do;
/*	proc printto log="&badlog" print="&badfile";
	run;*/

	data new;
	file log ps=500;
	length name $ 40;
	name = "&&vnam&i";
		     put name;

%end;

/*** If variable passes pcut then output to middle data list ***/

%else %do;

/*proc printto log=log print=print;
run;*/
	data new;
	file log ps=500;
	length name $ 40;
	name = "&&vnam&i";
		     put name;

%end;

/*** For each of these cases, produce the output ***/
/*** Print the means and N ***/

options ps=20;

data tpzweic;
	set zweic;
	if rindep = -1 then mnindep = .;

	proc print noobs data = tpzweic split='*';
		var rindep _freq_ mnindep mndepend mnote flag;
		label _freq_ = "N" 
			  rindep = "Rank"
			  flag = 'Notes'
			  mnote = 'Missing'
			  mndepend = "Mean of*&targetv"
	  		  mnindep = "Mean of*&&vnam&i";
		title2 "Plot and Means of &&vnam&i and &targetv by Rankings - &&vnam&i is &&lab&i";
		where rindep ne .;
		footnote ' ';
   run;

/*** Make the Plot ***/

options ps=50;


proc plot data = zweic hpercent=90 vpercent=75 nolegend;
	plot mndepend*mnindep=symbol;
			label mndepend = "&targetv" 
	  			  mnindep = "Variable &&vnam&i: &&lab&i";
title2 "&groups Point Means Plot of &targetv with &&vnam&i - &&lab&i";
title3 "&groups Mean Points R-Squared is &rsquare Log=&lrsquare SquareRoot=&srsquare Inverse=&irsquare  Offset Used for log,inverse=&offs";
title4 "&later &pvalue";
where rindep ne .;

/*** Finish with the bad Rsquare variables ***/

%end;

/*** Finish the do loop to analyze each variable ***/

%end;

/*** Print the final listings of variables ***/

options msglevel=I notes;
run;

%mend  ;







/*** Test it out




libname dma "\\dbmkt-svr\f\Lenscrafters\Sales Model Data";
libname dmacdb "\\dbmkt-svr\f\Lenscrafters\Sales Model Data\dma_sales_by_week";


%let modvars = AAA_Circ
AAA_Circ_PWEEK1
LC_LISTENERS
LC_LISTENERS_log
LC_LISTENERS_sqrt;


data reg1;
	set dma.dma_sales_by_week6_vars;

MOD_TARGET = CO_Total_Flash_Doll_DMA;
MOD_TARGET_LOG = log(CO_Total_Flash_Doll_DMA);

LC_LISTENERS_log = log(LC_LISTENERS + 1);
LC_LISTENERS_sqrt = sqrt(LC_LISTENERS);

drop dma fiscal_week2 CO_Total_Flash_Doll_DMA IND_NONPROMO_PERIOD highly correlated;


%triplot(reg1, MOD_TARGET, groups=10, rsqcut=0.8, pcut=0.00001, specify=keep,
		 vars=&modvars, mmiss=0);
run;

%triplot(reg1, MOD_TARGET_LOG, groups=10, rsqcut=0.999, pcut=0.00001, specify=keep,
		 vars=&modvars, mmiss=0);
run;

***/

