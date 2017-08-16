require 'rails'
require 'couch_tap'
require "yaml"
require 'mysql2'

DIR = File.dirname(__FILE__)

#DIR = File.dirname(__FILE__)
#require DIR + '/../config/environment' for loading rails environment
require DIR.to_s + '/config/environment' #for loading rails environment

couch_mysql_path = DIR.to_s + "/config/couch_mysql.yml"
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

changes "http://#{couch_username}:#{couch_password}@#{couch_host}:#{couch_port}/#{couch_db}" do
  # Which database should we connect to?
  logger.info("Successfully connected to couchdb: #{couch_db} available at #{couch_host}")
  database "#{mysql_adapter}://#{mysql_username}:#{mysql_password}@#{mysql_host}:#{mysql_port}/#{mysql_db}"
  logger.info("Successfully connected to Mysql DB: #{mysql_db} available at #{mysql_host}")
  #StatusCouchdb Document Type

  document 'type' => "StockLevelCouchdb" do |doc|
    #doc_id = doc.document["_id"]
    consumption_rate = doc.document["consumption_rate"]
    date = doc.document["date"].to_date.strftime('%Y-%m-%d') rescue doc.document["date"]
    dispensations = doc.document["dispensations"]
    location = doc.document["location"]
    prescriptions = doc.document["prescriptions"]
    receipts = doc.document["receipts"]
    site_code = doc.document["site_code"]
    stock_level = doc.document["stock_level"]
    supervision_verification = doc.document["supervision_verification"]
    supervision_verification_in_details = doc.document["supervision_verification_in_details"]
    relocations = doc.document["relocations"]
    
    data = {}
    data["prescriptions"] = prescriptions
    data["dispensations"] = dispensations
    data["consumption_rate"] = consumption_rate
    data["receipts"] = receipts
    data["stock_level"] = stock_level
    data["supervision_verification"] = supervision_verification
    data["supervision_verification_in_details"] = supervision_verification_in_details
    
    #################### START###################################################

    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id
    relocation_id = Definition.where(:name => "relocation").first.id
    drug_given_to_id = Definition.where(:name => "People who received drugs").first.id
    drug_prescribed_id = Definition.where(:name => "People prescribed drug").first.id
    drug_stock_level_id = Definition.where(:name => "Stock level").first.id
    drug_rate_id = Definition.where(:name => "Drug rate").first.id
    receipts_id = Definition.where(:name => "New Delivery").first.id
    clinic_id = Definition.where(:name => "Clinic verification").first.id
    supervision_id = Definition.where(:name => "Supervision verification").first.id
    supervision_in_detail_id = Definition.where(:name => "Supervision verification in detail").first.id
    month_of_stock_defn = Definition.find_by_name('Month of Stock').id
    site_id = Site.find_by_site_code(site_code).id  rescue nil
    
    (data['prescriptions'] || []).each do |prescription|
      pres_obs = Observation.where(:site_code => site_code,
        :definition_id => prescription_id,
        :value_drug => prescription['drug_inventory_id'],
        :value_date => date
      ).first

      if pres_obs.blank?
        Observation.create({:site_code => site_code,
            :site_id => site_id,
            :definition_id => prescription_id,
            :value_numeric => prescription['total'],
            :value_drug => prescription['drug_inventory_id'],
            :value_date => date})
      else
        pres_obs.value_numeric = prescription['total']
        pres_obs.save
      end
      
      pres_to = Observation.where(:site_code => site_code,
        :definition_id => drug_prescribed_id,
        :value_drug => prescription['drug_inventory_id'],
        :value_date => date
      ).first

      if pres_to.blank?
        Observation.create({:site_code => site_code,
            :site_id => site_id,
            :definition_id => drug_prescribed_id,
            :value_numeric => prescription['total_patients'],
            :value_drug => prescription['drug_inventory_id'],
            :value_date => date})
      else
        pres_to.value_numeric = prescription['total_patients']
        pres_to.save
      end
    end

    (data['dispensations'] || []).each do |dispensation|
      disp_obs = Observation.where(:site_code => site_code,
        :definition_id => dispensation_id,
        :value_drug => dispensation['drug_inventory_id'],
        :value_date => date
      ).first

      if disp_obs.blank?
        Observation.create({:site_code => site_code,
            :site_id => site_id,
            :definition_id => dispensation_id,
            :value_numeric => dispensation['total'],
            :value_drug => dispensation['drug_inventory_id'],
            :value_date => date})
      else
        disp_obs.value_numeric = dispensation['total']
        disp_obs.save
      end

      disp_to = Observation.where(:site_code => site_code,
        :definition_id => drug_given_to_id,
        :value_drug => dispensation['drug_inventory_id'],
        :value_date => date
      ).first

      if disp_to.blank?
        Observation.create({:site_code => site_code,
            :site_id => site_id,
            :definition_id => drug_given_to_id,
            :value_numeric => dispensation['total_patients'],
            :value_drug => dispensation['drug_inventory_id'],
            :value_date => date})
      else
        disp_to.value_numeric = dispensation['total_patients']
        disp_to.save
      end
    end

    (data['relocations'] || []).each do |key,value|
      next if value == 0
      relocation_obs = Observation.where(:site_code => site_code,
        :definition_id => relocation_id,
        :value_drug => key,
        :value_date => date
      ).first

      if relocation_obs.blank?
        Observation.create({:site_code => site_code,
            :site_id => site_id,
            :definition_id => relocation_id,
            :value_numeric => value,
            :value_drug => key,
            :value_date => date})
      else
        relocation_obs.value_numeric = value
        relocation_obs.save
      end

    end

    (data['receipts'] || []).each do |key,value|
      next if value == 0
      receipts_ob = Observation.where(:site_code => site_code,
        :definition_id => receipts_id,
        :value_drug => key,
        :value_date => date
      ).first

      if receipts_ob.blank?
        Observation.create({:site_code => site_code,
            :site_id => site_id,
            :definition_id => receipts_id,
            :value_numeric => value,
            :value_drug => key,
            :value_date => date})
      else
        receipts_ob.value_numeric = value
        receipts_ob.save
      end

    end

    (data['stock_level'] || []).each do |drug_id, value|
      relocation_obs = Observation.where(:site_code => site_code,
        :definition_id => drug_stock_level_id,
        :value_drug => drug_id,
        :value_date => date
      ).first

      if relocation_obs.blank?
        Observation.create({:site_code => site_code,
            :site_id => site_id,
            :definition_id => drug_stock_level_id,
            :value_numeric => value,
            :value_drug => drug_id,
            :value_date => date})
      else
        relocation_obs.value_numeric = value
        relocation_obs.save
      end

    end

    (data['consumption_rate'] || []).each do |drug_id, value|
      relocation_obs = Observation.where(:site_code => site_code,
        :definition_id => drug_rate_id,
        :value_drug => drug_id,
        :value_date => date
      ).first

      if relocation_obs.blank?
        Observation.create({:site_code => site_code,
            :site_id => site_id,
            :definition_id => drug_rate_id,
            :value_numeric => value.round(2),
            :value_drug => drug_id,
            :value_date => date})
      else
        relocation_obs.value_numeric = value.round(2)
        relocation_obs.save
      end

    end

    #.............................................................................
    (data['supervision_verification'] || []).each do |drug_id, value|
      relocation_obs = Observation.where(:site_code => site_code,
        :definition_id => supervision_id,
        :value_drug => drug_id,
        :value_date => date
      ).first

      if relocation_obs.blank?
        Observation.create({:site_code => site_code,
            :site_id => site_id,
            :definition_id => drug_rate_id,
            :value_numeric => value,
            :value_drug => drug_id,
            :value_date => date})
      else
        relocation_obs.value_numeric = value
        relocation_obs.save
      end

    end

    (data['clinic_verification'] || []).each do |drug_id, value|
      relocation_obs = Observation.where(:site_code => site_code,
        :definition_id => clinic_id,
        :value_drug => drug_id,
        :value_date => date
      ).first

      if relocation_obs.blank?
        Observation.create({:site_code => site_code,
            :site_id => site_id,
            :definition_id => drug_rate_id,
            :value_numeric => value,
            :value_drug => drug_id,
            :value_date => date})
      else
        relocation_obs.value_numeric = value
        relocation_obs.save
      end

    end

    (data['supervision_verification_in_details'] || []).each do |drug_id, values|
      next if values.blank?
      relocation_obs = Observation.where(:site_code => site_code,
        :definition_id => supervision_in_detail_id,
        :value_drug => drug_id,
        :value_date => date
      ).first

      if relocation_obs.blank?
        value_text_str = "{previous_verified_stock:#{values['previous_verified_stock']},"
        value_text_str += "earliest_expiry_date:#{values['earliest_expiry_date']},"
        value_text_str += "expiring_units:#{values['expiring_units']}}"
        Observation.create({:site_code => site_code,
            :site_id => site_id,
            :definition_id => supervision_in_detail_id,
            :value_numeric => values['verified_stock'],
            :value_drug => drug_id,
            :value_text => value_text_str,
            :value_date => date})
      else
        value_text_str = "{previous_verified_stock:#{values['previous_verified_stock']},"
        value_text_str += "earliest_expiry_date:#{values['earliest_expiry_date']},"
        value_text_str += "expiring_units:#{values['expiring_units']}}"

        relocation_obs.value_numeric =  values['verified_stock']
        relocation_obs.value_text = value_text_str
        relocation_obs.save
      end

    end
    #.............................................................................
    ##### calculating month of stock start #################
    drugs = Observation.find_by_sql("SELECT DISTINCT value_drug FROM observations where voided = 0")
    sites = Site.where(:active => 1)
    (sites || []).each do |site|
      puts "calculating for site : #{site.name}"
      (drugs || []).each do |drug|
        month_of_stock = Observation.calculate_month_of_stock(drug.value_drug, site.id)

        unless (month_of_stock.is_a? String ||  month_of_stock.nan? || month_of_stock.to_s.downcase == "infinity")
          puts "Month of stock : #{month_of_stock} for drug #{drug.value_drug} "
          Observation.create({:site_id => site.id,
              :definition_id => month_of_stock_defn,
              :value_numeric => month_of_stock.to_f.round(3),
              :value_drug => drug.value_drug,
              :site_code => site.site_code,
              :value_date => Date.today})

        end
      end
    end
    ##### calculating month of stock end#################

    pulled_time = PullTracker.where(:'site_code' => site_code).first

    if pulled_time.blank?
      pulled_time = PullTracker.new()
      pulled_time.site_code = site_code
    end
    pulled_time.pulled_datetime = ("#{date.to_date} #{Time.now().strftime('%H:%M:%S')}")
    pulled_time.save
    #################### END ####################################################

    logger.info("Done upating MySQL db")
  end

end

def record_pulled_datetime(site_code, date)

  pulled_time = PullTracker.where(:'site_code' => site_code).first

  if pulled_time.blank?
    pulled_time = PullTracker.new()
    pulled_time.site_code = site_code
  end
  pulled_time.pulled_datetime = ("#{date.to_date} #{Time.now().strftime('%H:%M:%S')}")
  pulled_time.save
  puts "Recorded for :#{site.name}, Date: #{pulled_time.pulled_datetime}"
end