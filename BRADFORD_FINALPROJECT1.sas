*** Intro to Statistical Programming - Final Project ***;

LIBNAME PROJECT "C:\Users\ethan\OneDrive\Desktop\PHST 620\Final";

PROC CONTENTS DATA=PROJECT.SURGERIES;
RUN;
PROC CONTENTS DATA=PROJECT.SMOKING;
RUN;

*Bringing datasets into work library;
DATA SURGERIES;
SET PROJECT.SURGERIES;
RUN;

DATA SMOKING;
SET PROJECT.SMOKING;
RUN;

*Merging datasets;
PROC SORT DATA=SURGERIES;
BY PT_ID;
RUN;
PROC SORT DATA=SMOKING;
BY PT_ID;
RUN;

DATA COMPLETE;
MERGE SURGERIES SMOKING;
BY PT_ID;
RUN;


*Determining First and Last Event Dates in the Study Data;
PROC TABULATE DATA=COMPLETE;
VAR EVENT_DATE;
TABLE EVENT_DATE, (MIN MAX)*F=MMDDYY10. ;
RUN;

*Counting missing values for Age;
PROC MEANS DATA=COMPLETE NMISS;
VAR AGE;
RUN;

*Filling missing values for Age;
PROC SORT DATA=COMPLETE;
BY PT_ID EVENT_DATE;
RUN;

DATA COMPLETE1;
SET COMPLETE;
BY PT_ID;
RETAIN RAGE;
IF FIRST.PT_ID THEN RAGE=AGE;
RETAIN REVENT_DATE;
IF FIRST.PT_ID THEN REVENT_DATE=EVENT_DATE;
NEWAGE = RAGE + ((EVENT_DATE - REVENT_DATE)/365.25);
DROP AGE RAGE REVENT_DATE;
RENAME NEWAGE=AGE;
RUN;

PROC MEANS DATA=COMPLETE1 NMISS;
VAR AGE;
RUN;


*Creating table of demographics;

/*Creating format to make interpretation easier*/;
PROC FORMAT;
VALUE RACEFT 
	  1-2 = 'Native American'
	    3 = 'African American non-Hispanic'
		4 = 'Hispanic'
		8 = 'Asian'
		9 = 'White non-Hispanic';
RUN;
PROC FORMAT FMTLIB;
RUN;

PROC SORT DATA=COMPLETE1 OUT=COMPLETE2 NODUPKEY;
BY PT_ID;
RUN;
PROC FREQ DATA=COMPLETE2;
TABLES RACE*(SEX HOSMKG);
FORMAT RACE RACEFT. ;
RUN;

*Creating Table for number of surgeries by age;
PROC FORMAT;
VALUE AGEFT 
0- <1 = 'Under 1'
1- <5 = '1- Under 5'
5- <18= '5- Under 18'
18- <30= '18- Under 30'
30- <50= '30- Under 50'
50- <65= '50- Under 65'
65- <75= '65- Under 75'
75- high= 'Above 75';
RUN;

DATA COMPLETE3;
SET COMPLETE1;
RETAIN AGECAT;
AGECAT=AGE;
FORMAT AGECAT AGEFT.;
RUN;

PROC SORT DATA=COMPLETE3 NODUPKEY;
BY PT_ID;
RUN;

PROC TABULATE DATA=COMPLETE3;
CLASS RACE AGECAT;
TABLE RACE ALL, AGECAT*N / MISSTEXT = '0';
FORMAT RACE RACEFT.;
LABEL AGECAT='AGE AT FIRST SURGERY';
RUN;

*Creating demographics table with age category, sex, and smoking status;

PROC TABULATE DATA=COMPLETE3;
CLASS AGECAT SEX HOSMKG;
TABLE AGECAT, (SEX HOSMKG)*ROWPCTN ALL*COLPCTN;
RUN;

*Re-sorting Data ;
TITLE 'STEP 8';
PROC SORT DATA=COMPLETE1 OUT=COMPLETE4;
BY PT_ID EVENT_DATE;
RUN;

*Finding combinations of surgical procedures;
DATA COMPLETE6;
SET COMPLETE4;
BY PT_ID EVENT_DATE;
RETAIN CONDX1;
RETAIN CONDX2;
FORMAT CONDX2 $9. CONDX1 $9.;
IF FIRST.EVENT_DATE THEN CONDX2='';
ELSE CONDX2=CONDX;
IF FIRST.EVENT_DATE THEN CONDX1=CONDX;
ELSE CONDX1='';
RUN;
PROC PRINT DATA=COMPLETE6;
RUN;

DATA TEMPORARY1;
SET COMPLETE6;
BY PT_ID EVENT_DATE;
IF FIRST.EVENT_DATE THEN DELETE;
DROP CONDX1;
RUN;

DATA TEMPORARY2;
SET COMPLETE6;
BY PT_ID EVENT_DATE;
IF FIRST.EVENT_DATE THEN OUTPUT;
DROP CONDX2;
RUN;

DATA COMPLETE7;
MERGE TEMPORARY2 TEMPORARY1;
BY PT_ID EVENT_DATE;
DROP CONDX;
RUN;
PROC PRINT DATA=COMPLETE7;
RUN;

PROC TABULATE DATA=COMPLETE7;
CLASS CONDX1 CONDX2;
TABLES CONDX1, CONDX2;
RUN;

*Creating counter and frequency table for patients who had more than one surgery in a day;
PROC SORT DATA=COMPLETE7 OUT=COMPLETE8;
BY PT_ID EVENT_DATE;
RUN;
DATA COMPLETE9;
SET COMPLETE8;
RETAIN SURGCOUNTER;
BY PT_ID EVENT_DATE;
IF FIRST.EVENT_DATE THEN DO;
SURGCOUNTER=1;
IF CONDX2 NE '' THEN SURGCOUNTER+1;
ELSE SURGCOUNTER=1;
OUTPUT;
END;
RUN;
PROC FREQ DATA=COMPLETE9;
TABLES SURGCOUNTER;
RUN;

*Calculating mean age of death by smoking status and race;
PROC MEANS DATA=COMPLETE2 MEAN MEDIAN MIN MAX MAXDEC=2;
VAR AGE;
CLASS RACE HOSMKG;
WHERE OUTCOME=1;
FORMAT RACE RACEFT.;
TITLE 'MEAN AGE OF DEATH BY SMOKING STATUS AND RACE';
RUN;

*Conducting two-sample t-test to see effect of smoking on age at death;
DATA COMPLETE5 (WHERE=(OUTCOME=1));
SET COMPLETE1;
RUN;
PROC PRINT DATA=COMPLETE5;
RUN;

PROC TTEST DATA=COMPLETE5 SIDES=2 ALPHA=0.05;
CLASS HOSMKG;
VAR AGE;
RUN;

*Conducting One-Way ANOVA to see effect of race on age at death;

PROC GLM DATA=COMPLETE5;
CLASS RACE;
MODEL AGE=RACE / SS3;
MEANS TYPE / TUKEY;
TITLE "ANOVA AND MULTIPLE COMPARISONS USING TUKEY HSD";
FORMAT RACE RACEFT.;
RUN;

*Creating a boxplot showing mean age of death for non-smoking and smoking groups;
PROC SGPLOT DATA=COMPLETE5;
VBOX AGE / category=HOSMKG;
TITLE 'BOXPLOT SHOWING AVERAGE AGE AT DEATH FOR NON-SMOKING (0) AND SMOKING (1) INDIVIDUALS';
RUN;
