#require 'rails'
require "yaml"
require 'mysql2'
require "json"
require 'net/http'


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
# uri = URI.parse"http://#{couch_username}:#{couch_password}@#{couch_host}:#{couch_port}/#{couch_db}" #do
# uri = URI.parse("http://example.org")

# Shortcut
#response = Net::HTTP.post_form(uri, {"user[name]" => "testusername", "user[email]" => "testemail@yahoo.com"})

# Full control
# http = Net::HTTP.new(uri.host, uri.port)

# request = Net::HTTP::Post.new(uri.request_uri)
# request.set_form_data({"user[name]" => "testusername", "user[email]" => "testemail@yahoo.com"})

# response = http.request(request)
# render :json => response.body
# info = JSON.parse(`curl -X GET http://#{username}:#{password}@#{ip_address}:#{port}/#{database}/_design/#{doc_type}/_view/by_date?key=\\\"#{key}\\\"`)
lett = JSON.parse(`curl -X GET http://admin:password@127.0.0.1:5984/stock_levels/_all_docs?include_docs=true`)
# puts lett["rows"]
  # Which database should we connect to?
  puts("Successfully connected to couchdb: #{couch_db} available at #{couch_host}")
  database  = "#{mysql_adapter}://#{mysql_username}:#{mysql_password}@#{mysql_host}:#{mysql_port}/#{mysql_db}"
  puts ("Successfully connected to Mysql DB: #{mysql_db} available at #{mysql_host}")
  #StatusCouchdb Document Type

  lett["rows"].each do
    puts("hey")
  end
   lett["rows"].each do |doc|
    consumption_rate = doc["doc"]["consumption_rate"]
    date = doc["doc"]["date"].to_date.strftime('%Y-%m-%d') rescue doc["doc"]["date"]
    dispensations = doc["doc"]["dispensations"]
    #location = doc["doc"]["location"]
    prescriptions = doc["doc"]["prescriptions"]
    receipts = doc["doc"]["receipts"]
    site_code = doc["doc"]["site_code"]
    stock_level = doc["doc"]["stock_level"]
    supervision_verification = doc["doc"]["supervision_verification"]
    supervision_verification_in_details = doc["doc"]["supervision_verification_in_details"]
    relocations = doc["doc"]["relocations"]
    
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


    puts(data)
    if date
      
    Kernel.system("rails runner script/counch_sync_main.rb '#{data.to_json}'")
    else
      
    end

  end

# end