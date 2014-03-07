
require 'rest-client'

$prescription_id = Definition.where(:name => "prescription").first.id
$dispensation_id = Definition.where(:name => "dispensation").first.id
$stock_id = Definition.where(:name => "stock").first.id
 
def start

  sites = YAML.load_file("#{Rails.root.to_s}/config/sites.yml")
  (sites || []).each do |key, value|
    puts "Getting Data For Site #{key}"
    unless value.blank?

      date = Date.today
      data = JSON.parse(RestClient.post("http://#{value}/drug/art_summary_dispensation", {:date=>date}))
      site = Site.where(:name => key).first_or_create
      record(site,date ,data)
    end

  end

end

def record(site, date,data)


  (data['prescriptions'] || []).each do |key,prescription|
    Observation.create({:site_id => site.id,
        :definition_id => $prescription_id,
        :value_numeric => prescription['bottles'],
        :value_drug => key,
        :value_date => date
      })
  end

  (data['dispensations'] || []).each do |key,dispensation|
    Observation.create({:site_id => site.id,
        :definition_id => $dispensation_id,
        :value_numeric => dispensation['bottles'],
        :value_drug => key,
        :value_date => date
      })
  end

  (data['stock'] || []).each do |key, stock|
    Observation.create({:site_id => site.id,
        :definition_id => $stock_id,
        :value_numeric => stock['level'],
        :value_drug => key,
        :value_date => date
      })
  end

end

start
