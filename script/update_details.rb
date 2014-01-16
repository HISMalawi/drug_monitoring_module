
require 'rest-client'

$prescription_id = Definition.where(:name => "prescription").first.id
$dispensation_id = Definition.where(:name => "dispensation").first.id
def start

  sites = YAML.load_file("#{Rails.root.to_s}/config/sites.yml")
  (sites || []).each do |key, value|
    puts "Getting Data For Site #{key}"
    date = '2013-09-02'
    data = JSON.parse(RestClient.post("http://192.168.18.208:3002/drug/art_summary_dispensation", {:date=>date}))
    site = Site.where(:name => key).first_or_create
    record(site,date ,data)
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
end

start