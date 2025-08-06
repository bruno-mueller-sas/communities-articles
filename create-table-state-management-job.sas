/*
 * create a new Table State Management job
 * the example is based on the job
 * Sample: Import cas-shared-default Public data
 */
%let BASE_URI = %sysfunc(getoption(servicesbaseurl));
%put NOTE: &=base_uri;

/*
 * macro variables used
 * 
 */
%let caslib = Sales;
%let jobname = From Code Import &caslib caslib;
%let description = &jobname;
%let parent_folder_uri = /folders/folders/f1e9bbb2-97e7-4358-8ca7-77750606a69a;

/*
 * create a new json file with values changed
 * jrtmp is the new file from which the job is created
 * the json template comes after the CARDS statement
 */
filename jrtmp temp;
data _null_;
infile cards truncover;
input @1 line $char32767.;
/* resolve macro variables */
line = resolve(line);
file jrtmp;
put line;
cards;
{
  "arguments": {
    "options": "{\"enabled\":true,\"type\":\"IMPORT\",\"settings\":{ \"varChars\":false, \"getNames\":true, \"allowTruncation\":true, \"charMultiplier\":2, \"stripBlanks\":false, \"guessRows\":200, \"encoding\":\"utf-8\", \"delimiter\":\",\",\"refresh\":true, \"refreshMode\":\"newer\", \"successJobId\":\"\" }, \"selectors\":[{\"serverName\":\"cas-shared-default\",\"inputCaslib\":\"&caslib\",\"outputCaslib\":\"&caslib\",\"filter\":\"or(endsWith(name,'.csv'),endsWith(name,'.sas7bdat'),endsWith(name,'.xls'),endsWith(name,'.xlsx'))\",\"settings\":{}}]}"
  },
  "description": "&description",
  "jobDefinitionUri": "/jobDefinitions/definitions/c124c346-e642-4fc0-a2c1-5fdcb194a0ac",
  "name": "&jobname",
  "properties": [
    {
      "name": "class",
      "value": "admin"
    },
    {
      "name": "sampleJob",
      "value": "copy"
    }
  ],
  "version": 3
}
;

/*
 * print the new file for verification
 */
data _null_;
	rc = jsonpp("jrtmp", "log");
run;


/*
 * call the API to create the job
 */
filename resp temp;
proc http
  method=post
  url="&base_uri/jobExecution/jobRequests?parentFolderUri=&parent_folder_uri"
  in=jrtmp
  out=resp
  oauth_bearer=sas_services
  verbose
;
headers
  "Accept" = "application/vnd.sas.job.execution.job.request+json"
  "Content-Type" = "application/vnd.sas.job.execution.job.request+json"
;
run;
/*
 * a status code of 201 means the job has been created
 * if there is an error, like name does alread exist
 * a JSON is returned with more detailed information
 */
%put NOTE: &=SYS_PROCHTTP_STATUS_CODE;
%put NOTE: &=SYS_PROCHTTP_STATUS_PHRASE;
%put NOTE: JSON Result;
%let rc = %sysfunc(jsonpp(resp, log));

