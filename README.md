## Description

I wrote a cookbook to handle SQL Server post-installation tasks (create shared folders, change service account and execute SQL Queries). During the tests, I observed an issue where the resource windows_service makes the chef-client silently fails 50% of the time. The process is completely killed without returning any exception or error message.

The worst part is if I run the chef-client again with the same conditions, the new execution may works. I am controlling for those factors at each run:
- The same cookbook is run with not change made to the code
- Running on the same machine (Windows Server 2012 R2 hosted on AWS EC2)
- Running on the same conditions
  I am executing a cleanup.ps1 script to reset the machine exactly how it was before chef run

I reproduced the issue on two separate machines and with different sets of windows service:
- Scenario A : MSSQL and SQLSERVERAGENT
- Scenario B : AmazonSSMAgent and AWSLiteAgent

## Chef Version
Chef Client, version 12.19.36

## Platform Version
Windows Server 2012 R2 Version 6.3 Build 9600
Originally built with AWS EC2
Windows_Server-2012-R2_RTM-English-64Bit-Base-2017.05.10 - ami-271b6d31

## Replication Case

You can use reproduce the problem by using the following resources in a cookbook. You can also download the test cookbook in this zip file.

```Ruby
#STEP 01 - Resource before service change
file 'C:\\test01.txt' do
  content 'Resource before service change'
end

#STEP 02 - Service account change
windows_service 'AmazonSSMAgent stop' do
	service_name 'AmazonSSMAgent'
	timeout 30
	retries 5
	action :stop
end

windows_service 'AWSLiteAgent' do
	service_name 'AWSLiteAgent'
	run_as_user ".\\svc-sql-new"
	run_as_password "Passw0rd"
	action :restart
end

windows_service 'AmazonSSMAgent' do
	service_name 'AmazonSSMAgent'
	run_as_user ".\\svc-sql-new"
	run_as_password "Passw0rd"
	action :restart
end

# STEP 03 - Resource after service change
file 'C:\\test02.txt' do
  content 'Resource after service change'
end
```

JSON file I am using to run the cookbook
```json
{
   "run_list":[
      "recipe[cookbook_cvgx_windows2012r2-sql_postinstall::default]"
   ]
}
```

Command used to execute the client
```PowerShell
PS C:\chef> chef-client -l debug -j C:\chef\runlist_sql_post.json --logfile C:\chef\chef-client.log
```

## Client Output

The relevant output of the chef-client run or a link to a gist of the entire run, if there is one.

The debug output (chef-client -l debug) may be useful, but please link to a gist, or truncate it.

### Expected behavior (happen ~50% of the time)
```PowerShell
PS C:\chef> chef-client -l debug -j C:\chef\runlist_sql_post.json --logfile C:\chef\chef-client.log
Starting Chef Client, version 12.19.36
resolving cookbooks for run list: ["cookbook_cvgx_windows2012r2-sql_postinstall::default"]
Synchronizing Cookbooks:
  - cookbook_cvgx_windows2012r2-sql_postinstall (0.2.6)
Installing Cookbook Gems:
Compiling Cookbooks...
Converging 5 resources
Recipe: cookbook_cvgx_windows2012r2-sql_postinstall::default
  * file[C:\test01.txt] action create
    - create new file C:\test01.txt
    - update content in file C:\test01.txt from none to f8a3c4
    --- C:\test01.txt   2017-06-02 12:44:13.000000000 -0400
    +++ C:\chef-test0120170602-5188-lunfkp.txt  2017-06-02 12:44:13.000000000 -0400
    @@ -1 +1,2 @@
    +Resource before service change
  * windows_service[AmazonSSMAgent stop] action stop
    - stop service windows_service[AmazonSSMAgent stop]
  * windows_service[AWSLiteAgent] action restart
    - restart service windows_service[AWSLiteAgent]
  * windows_service[AmazonSSMAgent] action restart
    - restart service windows_service[AmazonSSMAgent]
  * file[C:\test02.txt] action create
    - create new file C:\test02.txt
    - update content in file C:\test02.txt from none to 227efa
    --- C:\test02.txt   2017-06-02 12:44:20.000000000 -0400
    +++ C:\chef-test0220170602-5188-1v5jhas.txt 2017-06-02 12:44:20.000000000 -0400
    @@ -1 +1,2 @@
    +Resource after service change

Running handlers:
Running handlers complete
Chef Client finished, 5/5 resources updated in 12 seconds
PS C:\chef>
```

### Observed issue  (~50% of the time)
```PowerShell
PS C:\chef> chef-client -l debug -j C:\chef\runlist_sql_post.json --logfile C:\chef\chef-client.log
Starting Chef Client, version 12.19.36
resolving cookbooks for run list: ["cookbook_cvgx_windows2012r2-sql_postinstall::default"]
Synchronizing Cookbooks:
  - cookbook_cvgx_windows2012r2-sql_postinstall (0.2.6)
Installing Cookbook Gems:
Compiling Cookbooks...
Converging 5 resources
Recipe: cookbook_cvgx_windows2012r2-sql_postinstall::default
  * file[C:\test01.txt] action create
    - create new file C:\test01.txt
    - update content in file C:\test01.txt from none to f8a3c4
    --- C:\test01.txt   2017-06-02 12:36:42.000000000 -0400
    +++ C:\chef-test0120170602-4744-wm38ec.txt  2017-06-02 12:36:42.000000000 -0400
    @@ -1 +1,2 @@
    +Resource before service change
  * windows_service[AmazonSSMAgent stop] action stop
    - stop service windows_service[AmazonSSMAgent stop]
  * windows_service[AWSLiteAgent] action restart
    - restart service windows_service[AWSLiteAgent]
  * windows_service[AmazonSSMAgent] action restartPS C:\chef>
```

## Stacktrace
No stacktrace.out (chef-client fails without producing one)
chef-client debug log available here:
- SQL Server Service Success
- SQL Server Service Failure
- AWS Service Success
- AWS Service Failure
