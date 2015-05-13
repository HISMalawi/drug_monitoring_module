About Drug Monitoring Dashboard

The Drug Monitoring Dashboard was built by Baobab Health Trust with the aim of supporting stock management in the HIV 
unit of the Malawi Government ministry of health.The drug monitoring dashboard works in two modes. The dashboard mode 
 which displays a map of the country and the number of notices at each of the sites. The other mode is th interactive 
 mode which allows the user to investigate the notices and process reports.
 
 
 Prerequisites For Installing Drug Monitoring Dashboard 
 
 The drug monitoring dashboard was written in Ruby on Rails. To install the application, the following are required:
 
 Ruby 1.8.7 (Programming language)
 Rubygems 1.3.7(ruby gem manager)
 Rails 3.2.16 (ruby web application framework)
 MySQL (database server)
 
 How To Install
 Before you start setting up the Drug Monitoring Dashboard ensure all the prerequisites are installed. Refer to the 
 "Setting Up Ruby And Rails" section of this document if you need help with this. 
 
 To setup the application, do the following :
 
 Step 1: Cloning the application
 - The application can be cloned from  https://github.com/BaobabHealthTrust/drug_monitoring_module.git 
 
 Step 2: Configure the application
 - In the folder that you cloned the application. Navigate to the config folder. 
 - Create a database.yml file based on the database.yml.example file. This is where you define the database name and 
  database access details. 
 
 Step 3: Setup Application Environment 
 - In the application folder, run the command: "bundle install". This will install all the required gems for the application.
  
 Step 4: Setup application database
 - Create the application database and initialise it. This can be done with this command: "bundle exec rake db:create db:migrate db:seed"
  
 Step 5: Run the Application
 - In the application folder, run the command "bundle exec rails s" or "bundle exec passenger start" to launch your application.
 
Getting Data
 
 The Drug Monitoring Dashboard is designed to get drug stock levels and utilization from sites with BART. The sites whose
 data will be captured are sites which are registered in the drug monitoring dashboard. BART has an api which when accessed
 gives the required data elements required for the drug monitoring dashboard. A script was written to capture this data
 and should be setup as a cron job to run daily and get the most recent data. This script in in the application's script
 folder and is called "init_site_details.rb".  
   
   
Setting Up Ruby And Rails

Step 1: Ruby and main packages installation
Using your terminal run the following command:

sudo apt-get install ruby build-essential libopenssl-ruby ruby1.8-dev 
ruby-dev mysql-client mysql-server git-core libmysql-ruby 
libmysqlclient-dev unzip rubygems 

Check if the ruby version is the correct one by running: (ruby -v) expected 1.8.7

Step 2: Downgrade Rubygems

wget http://rubyforge.org/frs/download.php/70697/rubygems-1.3.7.zip 
unzip rubygems-1.3.7.zip
ruby rubygems-1.3.7/setup.rb 

Check if the rubygems version is the correct one by running: (gem -v)   expected 1.3.7 

Step 3: Install initial gems
Install bundler  using the following command: 


