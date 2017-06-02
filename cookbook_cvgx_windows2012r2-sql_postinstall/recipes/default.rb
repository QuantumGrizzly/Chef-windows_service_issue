#
# Cookbook Name:: cookbook_cvgx_windows2012r2-sql_postinstall
# Recipe::	default
# Author: Sammy (sammy@company.com)
# Date: 05/31/2017
# Copyright (c) 2017 Company, All Rights Reserved.

#Load databag
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
