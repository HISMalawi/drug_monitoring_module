
require 'rest-client'

$prescription_id = Definition.where(:name => "prescription").first.id
$dispensation_id = Definition.where(:name => "dispensation").first.id
$relocation_id = Definition.where(:name => "relocation").first.id
$drug_given_to_id = Definition.where(:name => "People who received drugs").first.id
$drug_prescribed_id = Definition.where(:name => "People prescribed drug").first.id
$drug_stock_level_id = Definition.where(:name => "Stock level").first.id
$drug_rate_id = Definition.where(:name => "Drug rate").first.id
$receipts_id = Definition.where(:name => "New Delivery").first.id
$clinic_id = Definition.where(:name => "Clinic verification").first.id
$supervision_id = Definition.where(:name => "Supervision verification").first.id
$supervision_in_detail_id = Definition.where(:name => "Supervision verification in detail").first.id

def start

  sites = Site.where(:active => 1)
  (sites || []).each do |site|
    puts "Getting Data For Site #{site.name}"

      date = Date.today
      while date <= Date.today

        url = "http://#{site.ip_address}:#{site.port}/drug/art_stock_info?date=#{date}"
        data = JSON.parse(RestClient::Request.execute(:method => :post, :url => url, :timeout => 100000000)) rescue (
          puts "**** Error when pulling data from site #{site.name}"
          next
        )
        puts "............. #{site.name}: #{date}"
        record(site,date ,data)
        date += 1.day
      end
  end

  puts "Calculating Stock Levels"
  `rails runner #{Rails.root}/script/calculate_stock_levels.rb`

end

def record(site, date,data)

  (data['prescriptions'] || []).each do |prescription|
    pres_obs = Observation.where(:site_id => site.id,
      :definition_id => $prescription_id,
      :value_drug => prescription['drug_inventory_id'],
      :value_date => date
    ).first

    if pres_obs.blank?
      Observation.create({:site_id => site.id,
          :definition_id => $prescription_id,
          :value_numeric => prescription['total'],
          :value_drug => prescription['drug_inventory_id'],
          :value_date => date})
    else
      pres_obs.value_numeric = prescription['total']
      pres_obs.save
    end

    pres_to = Observation.where(:site_id => site.id,
      :definition_id => $drug_prescribed_id,
      :value_drug => prescription['drug_inventory_id'],
      :value_date => date
    ).first

    if pres_to.blank?
      Observation.create({:site_id => site.id,
          :definition_id => $drug_prescribed_id,
          :value_numeric => prescription['total_patients'],
          :value_drug => prescription['drug_inventory_id'],
          :value_date => date})
    else
      pres_to.value_numeric = prescription['total_patients']
      pres_to.save
    end
  end

  (data['dispensations'] || []).each do |dispensation|
    disp_obs = Observation.where(:site_id => site.id,
      :definition_id => $dispensation_id,
      :value_drug => dispensation['drug_inventory_id'],
      :value_date => date
    ).first

    if disp_obs.blank?
      Observation.create({:site_id => site.id,
          :definition_id => $dispensation_id,
          :value_numeric => dispensation['total'],
          :value_drug => dispensation['drug_inventory_id'],
          :value_date => date})
    else
      disp_obs.value_numeric = dispensation['total']
      disp_obs.save
    end

    disp_to = Observation.where(:site_id => site.id,
      :definition_id => $drug_given_to_id,
      :value_drug => dispensation['drug_inventory_id'],
      :value_date => date
    ).first

    if disp_to.blank?
      Observation.create({:site_id => site.id,
          :definition_id => $drug_given_to_id,
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
    relocation_obs = Observation.where(:site_id => site.id,
      :definition_id => $relocation_id,
      :value_drug => key,
      :value_date => date
    ).first

    if relocation_obs.blank?
      Observation.create({:site_id => site.id,
          :definition_id => $relocation_id,
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
    receipts_ob = Observation.where(:site_id => site.id,
                                       :definition_id => $receipts_id,
                                       :value_drug => key,
                                       :value_date => date
    ).first

    if receipts_ob.blank?
      Observation.create({:site_id => site.id,
                          :definition_id => $receipts_id,
                          :value_numeric => value,
                          :value_drug => key,
                          :value_date => date})
    else
      receipts_ob.value_numeric = value
      receipts_ob.save
    end

  end

  (data['stock_level'] || []).each do |drug_id, value|
    relocation_obs = Observation.where(:site_id => site.id,
      :definition_id => $drug_stock_level_id,
      :value_drug => drug_id,
      :value_date => date
    ).first

    if relocation_obs.blank?
      Observation.create({:site_id => site.id,
          :definition_id => $drug_stock_level_id,
          :value_numeric => value,
          :value_drug => drug_id,
          :value_date => date})
    else
      relocation_obs.value_numeric = value
      relocation_obs.save
    end

  end

  (data['consumption_rate'] || []).each do |drug_id, value|
    relocation_obs = Observation.where(:site_id => site.id,
      :definition_id => $drug_rate_id,
      :value_drug => drug_id,
      :value_date => date
    ).first

    if relocation_obs.blank?
      Observation.create({:site_id => site.id,
          :definition_id => $drug_rate_id,
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
    relocation_obs = Observation.where(:site_id => site.id,
      :definition_id => $supervision_id,
      :value_drug => drug_id,
      :value_date => date
    ).first

    if relocation_obs.blank?
      Observation.create({:site_id => site.id,
          :definition_id => $drug_rate_id,
          :value_numeric => value,
          :value_drug => drug_id,
          :value_date => date})
    else
      relocation_obs.value_numeric = value
      relocation_obs.save
    end

  end

  (data['clinic_verification'] || []).each do |drug_id, value|
    relocation_obs = Observation.where(:site_id => site.id,
      :definition_id => $clinic_id,
      :value_drug => drug_id,
      :value_date => date
    ).first

    if relocation_obs.blank?
      Observation.create({:site_id => site.id,
          :definition_id => $drug_rate_id,
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
    relocation_obs = Observation.where(:site_id => site.id,
      :definition_id => $supervision_in_detail_id,
      :value_drug => drug_id,
      :value_date => date
    ).first

    if relocation_obs.blank?
      value_text_str = "{previous_verified_stock:#{values['previous_verified_stock']},"
      value_text_str += "earliest_expiry_date:#{values['earliest_expiry_date']},"
      value_text_str += "expiring_units:#{values['expiring_units']}}"
      Observation.create({:site_id => site.id,
          :definition_id => $supervision_in_detail_id,
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
end


start
