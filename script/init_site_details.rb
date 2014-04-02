
require 'rest-client'

$prescription_id = Definition.where(:name => "prescription").first.id
$dispensation_id = Definition.where(:name => "dispensation").first.id
$relocation_id = Definition.where(:name => "relocation").first.id
$drug_given_to_id = Definition.where(:name => "People who received drugs").first.id
$drug_prescribed_id = Definition.where(:name => "People prescribed drug").first.id

def get_dates
  dates = [] ; curr_date = Date.today
  1.upto(90).collect do |n|
    dates << curr_date
    curr_date -= 1.day
  end
  return dates
end
 
def start
  dates = get_dates

  sites = YAML.load_file("#{Rails.root.to_s}/config/sites.yml")
  (sites || []).each do |key, value|
    (dates || []).each do |date|
      puts "Getting Data For Site #{key}, Date: #{date.strftime('%A, %d %B %Y')}"
      unless value.blank?

        url = "http://#{value}/drug/art_summary_dispensation?date=#{date}"
        data = JSON.parse(RestClient::Request.execute(:method => :post, :url => url, :timeout => 100000000)) rescue (
          puts "**** Error when pulling data from site #{key}"
         next
        )
        site = Site.where(:name => key).first_or_create
        record(site,date ,data)
      end
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
    Observation.create({:site_id => site.id,
                        :definition_id => $drug_prescribed_id,
                        :value_numeric => prescription['total_patients'],
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
    Observation.create({:site_id => site.id,
                        :definition_id => $drug_given_to_id,
                        :value_numeric => dispensation['total_patients'],
                        :value_drug => key,
                        :value_date => date
                       })
  end

  (data['relocations'] || []).each do |key,relocation|
    next if relocation["relocated"] == 0
    Observation.create({:site_id => site.id,
                        :definition_id => $relocation_id,
                        :value_numeric => relocation['relocated'],
                        :value_drug => key,
                        :value_date => date
                       })

  end

  (data['stock_level'].keys || []).each do |drug|

    data['stock_level'][drug].each do |key, value|
      $definition_id = Definition.where(:name => key).first.id
      if value.class.to_s == "Array"
        
        pills = value[0]
        date_of_count = value[1]
        next if date_of_count.blank?
        Observation.create({:site_id => site.id,
            :definition_id => $definition_id,
            :value_numeric => pills,
            :value_drug => drug,          
            :value_date => date_of_count
          })
      else

        Observation.create({:site_id => site.id,
            :definition_id => $definition_id,
            :value_numeric => value,
            :value_drug => drug,
            :value_date => date
          })
      end
    end
  end

end

start