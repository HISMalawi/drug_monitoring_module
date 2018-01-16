def get_couch_changes
  couch_mysql_path = Rails.root.to_s + "/config/couch_mysql.yml"
  db_settings = YAML.load_file(couch_mysql_path)
  couch_db_settings = db_settings["couchdb"]
  couch_host = couch_db_settings["host"]
  couch_db = couch_db_settings["database"]
  couch_port = couch_db_settings["port"]

  couch_address = "http://#{couch_host}:#{couch_port}/#{couch_db}/_changes?descending=true&include_docs=true"
  received_params = RestClient.get(couch_address)
  results = JSON.parse(received_params)
  couch_data = {}

  results.each do |key, values|
    values.each do |data|
      date = data["doc"]["date"].to_date.strftime('%Y-%m-%d') rescue nil
      next if date.blank?
      consumption_rate = data["doc"]["consumption_rate"]

      dispensations = data["doc"]["dispensations"]
      prescriptions = data["doc"]["prescriptions"]
      receipts = data["doc"]["receipts"]
      site_code = data["doc"]["site_code"]
      stock_level = data["doc"]["stock_level"]
      supervision_verification = data["doc"]["supervision_verification"]
      supervision_verification_in_details = data["doc"]["supervision_verification_in_details"]
      relocations = data["doc"]["relocations"]

      couch_data["date"] = date
      couch_data["site_code"] = site_code
      couch_data["prescriptions"] = prescriptions
      couch_data["dispensations"] = dispensations
      couch_data["consumption_rate"] = consumption_rate
      couch_data["receipts"] = receipts
      couch_data["stock_level"] = stock_level
      couch_data["supervision_verification"] = supervision_verification
      couch_data["supervision_verification_in_details"] = supervision_verification_in_details
      couch_data["relocations"] = relocations

      create_or_update_mysql_from_couch(couch_data, date)
    end rescue nil
  end
  return couch_data
  #render :text => couch_data.to_json and return
end

def create_or_update_mysql_from_couch(data, date)
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
  site_code = data["site_code"]
  date = data["date"]
  site_id = Site.find_by_site_code(site_code).id  rescue nil

  (data['prescriptions'] || []).each do |prescription|
    pres_obs = Observation.where(:site_id => site_id,
      :definition_id => prescription_id,
      :value_drug => prescription['drug_inventory_id'],
      :value_date => date
    ).first


    if pres_obs.blank?
      Observation.create({
          :site_id => site_id,
          :definition_id => prescription_id,
          :value_numeric => prescription['total'],
          :value_drug => prescription['drug_inventory_id'],
          :value_date => date})
    else
      pres_obs.value_numeric = prescription['total']
      pres_obs.save
    end

    pres_to = Observation.where(:site_id => site_id,
      :definition_id => drug_prescribed_id,
      :value_drug => prescription['drug_inventory_id'],
      :value_date => date
    ).first

    if pres_to.blank?
      Observation.create({
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
    disp_obs = Observation.where(:site_id => site_id,
      :definition_id => dispensation_id,
      :value_drug => dispensation['drug_inventory_id'],
      :value_date => date
    ).first

    if disp_obs.blank?
      Observation.create({
          :site_id => site_id,
          :definition_id => dispensation_id,
          :value_numeric => dispensation['total'],
          :value_drug => dispensation['drug_inventory_id'],
          :value_date => date})
    else
      disp_obs.value_numeric = dispensation['total']
      disp_obs.save
    end

    disp_to = Observation.where(:site_id => site_id,
      :definition_id => drug_given_to_id,
      :value_drug => dispensation['drug_inventory_id'],
      :value_date => date
    ).first

    if disp_to.blank?
      Observation.create({
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
    relocation_obs = Observation.where(:site_id => site_id,
      :definition_id => relocation_id,
      :value_drug => key,
      :value_date => date
    ).first

    if relocation_obs.blank?
      Observation.create({
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
    receipts_ob = Observation.where(:site_id => site_id,
      :definition_id => receipts_id,
      :value_drug => key,
      :value_date => date
    ).first

    if receipts_ob.blank?
      Observation.create({
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
    relocation_obs = Observation.where(:site_id => site_id,
      :definition_id => drug_stock_level_id,
      :value_drug => drug_id,
      :value_date => date
    ).first

    if relocation_obs.blank?
      Observation.create({
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
    relocation_obs = Observation.where(:site_id => site_id,
      :definition_id => drug_rate_id,
      :value_drug => drug_id,
      :value_date => date
    ).first

    if relocation_obs.blank?
      Observation.create({
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
    relocation_obs = Observation.where(:site_id => site_id,
      :definition_id => supervision_id,
      :value_drug => drug_id,
      :value_date => date
    ).first

    if relocation_obs.blank?
      Observation.create({
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
    relocation_obs = Observation.where(:site_id => site_id,
      :definition_id => clinic_id,
      :value_drug => drug_id,
      :value_date => date
    ).first

    if relocation_obs.blank?
      Observation.create({
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
    relocation_obs = Observation.where(:site_id => site_id,
      :definition_id => supervision_in_detail_id,
      :value_drug => drug_id,
      :value_date => date
    ).first

    if relocation_obs.blank?
      value_text_str = "{previous_verified_stock:#{values['previous_verified_stock']},"
      value_text_str += "earliest_expiry_date:#{values['earliest_expiry_date']},"
      value_text_str += "expiring_units:#{values['expiring_units']}}"
      Observation.create({
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
  #sites = Site.where(:active => 1)
  #(sites || []).each do |site|
  site = Site.find_by_site_code(site_code)
  date = date.to_date.strftime("%d-%b-%Y")
  puts "calculating for site : #{site.name} on #{date}"
  (drugs || []).each do |drug|
    month_of_stock = Observation.calculate_month_of_stock(drug.value_drug, site_id)

    unless (month_of_stock.is_a? String ||  month_of_stock.nan? || month_of_stock.to_s.downcase == "infinity")
      puts "Month of stock : #{month_of_stock} for drug #{drug.value_drug} "
      Observation.create({:site_id => site_id,
          :definition_id => month_of_stock_defn,
          :value_numeric => month_of_stock.to_f.round(3),
          :value_drug => drug.value_drug,
          :value_date => Date.today})

    end
  end

  #end
  ##### calculating month of stock end#################

  pulled_time = PullTracker.where(:'site_id' => site_id).first

  if pulled_time.blank?
    pulled_time = PullTracker.new()
    pulled_time.site_id = site_id
  end
  pulled_time.pulled_datetime = ("#{Date.today} #{Time.now().strftime('%H:%M:%S')}")
  pulled_time.save
  #################### END ####################################################

end

get_couch_changes