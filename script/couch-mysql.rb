#require 'rails'
require "yaml"
require 'mysql2'
require "json"
#require 'couch_tap'

DIR = File.dirname(__FILE__)
couch_mysql_path = "#{Rails.root}/config/couch_mysql.yml"
db_settings = YAML.load_file(couch_mysql_path)
couch_db_settings = db_settings["couchdb"]
couch_username = couch_db_settings["username"]
couch_password = couch_db_settings["password"]
couch_host = couch_db_settings["host"]
couch_db = couch_db_settings["database"]
couch_port = couch_db_settings["port"]

mysql_db_settings = db_settings["mysql"]
mysql_username = mysql_db_settings["username"]
mysql_password = mysql_db_settings["password"]
mysql_host = mysql_db_settings["host"]
mysql_db = mysql_db_settings["database"]
mysql_port = mysql_db_settings["port"]
mysql_adapter = mysql_db_settings["adapter"]

#reading db_mapping
#db_map_path = DIR.to_s + "/config/db_mapping.yml"
#db_maps = YAML.load_file(db_map_path)

client = Mysql2::Client.new(:host => mysql_host,
  :username => mysql_username,
  :password => mysql_password,
  :database => mysql_db
)
#raise Definition.first.inspect
#raise ActiveRecord::Base.inspect
changes "http://#{couch_username}:#{couch_password}@#{couch_host}:#{couch_port}/#{couch_db}" do
  # Which database should we connect to?
  logger.info("Successfully connected to couchdb: #{couch_db} available at #{couch_host}")
  database "#{mysql_adapter}://#{mysql_username}:#{mysql_password}@#{mysql_host}:#{mysql_port}/#{mysql_db}"
  logger.info("Successfully connected to Mysql DB: #{mysql_db} available at #{mysql_host}")
  #StatusCouchdb Document Type

  document 'type' => "StockLevelCouchdb" do |doc|
    consumption_rate = doc.document["consumption_rate"]
    date = doc.document["date"].to_date.strftime('%Y-%m-%d') rescue doc.document["date"]
    dispensations = doc.document["dispensations"]
    #location = doc.document["location"]
    prescriptions = doc.document["prescriptions"]
    receipts = doc.document["receipts"]
    site_code = doc.document["site_code"]
    stock_level = doc.document["stock_level"]
    supervision_verification = doc.document["supervision_verification"]
    supervision_verification_in_details = doc.document["supervision_verification_in_details"]
    relocations = doc.document["relocations"]
    
    data = {}
    data["date"] = date
    data["site_code"] = site_code
    data["prescriptions"] = prescriptions
    data["dispensations"] = dispensations
    data["consumption_rate"] = consumption_rate
    data["receipts"] = receipts
    data["stock_level"] = stock_level
    data["supervision_verification"] = supervision_verification
    data["supervision_verification_in_details"] = supervision_verification_in_details
    data["relocations"] = relocations

    
    Kernel.system("rails runner script/counch_sync_main.rb '#{data.to_json}'")

  end

end