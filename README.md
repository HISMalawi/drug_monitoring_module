 ========= National ART Stock Monitoring Dashboard =============

The National ART Stock Monitoring Dashboard was developed to aid the 
HIV unit department in the Ministry of Health (MOH) of the Malawi
government in their daily operations. This is accomplished by 
providing alerts, notifications and reports of stock

System Requirements

Ruby 1.9.3 and above


How to Install

1. After cloning the application from github, set up the required 
environment by running the following: 

	bundle install

2. create and configure database.yml file in the config directory.
This configuration can be based on the template file labelled 
database.yml.example in the config folder. 

3. Create sites.yml file in the config directory.

4. Initialise application database by running the following command.
	rake db:create db:migrate db:seed


Updating Site Data

The National ART Stock Monitoring dashboard gets its data from the various 
sites that it is connected to. To ensure that this data is colected on a 
daily basis, a script must be run to pull the data. Set a cron-job to run 
the script and pull the data.

The cron-job should run the script as follows:

	rails runner script/init_site_details.rb
