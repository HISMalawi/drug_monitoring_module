
require 'rest-client'

$prescription_id = Definition.where(:name => "prescription").first.id
$dispensation_id = Definition.where(:name => "dispensation").first.id
$relocation_id = Definition.where(:name => "relocation").first.id
$drug_given_to_id = Definition.where(:name => "People who received drugs").first.id
$drug_prescribed_id = Definition.where(:name => "People prescribed drug").first.id

def get_dates(site_name)
  site = Site.where(:'name' => site_name).first
  return if site.blank?
  last_pulled = PullTracker.where(:'site_id' => site.id).first

  dates = [] ; curr_date = Date.today ; last_pull_date = last_pulled.pulled_datetime.to_date rescue nil
  last_pull_date = (curr_date - 202.day) if last_pull_date.blank?

  while last_pull_date <= curr_date 
    dates << curr_date
    curr_date -= 1.day
  end
  return dates
end
 
def start

  sites = YAML.load_file("#{Rails.root.to_s}/config/sites.yml")
  (sites || []).each do |key, value|
    dates = get_dates(key)
    next if dates.blank?
    (dates.sort || []).each do |date|
      #puts "Getting Data For Site #{key}, Date: #{date.strftime('%A, %d %B %Y')}"
      unless value.blank?

        url = "http://#{value}/drug/art_summary_dispensation?date=#{date}"
        data = JSON.parse(RestClient::Request.execute(:method => :post, :url => url, :timeout => 100000000)) rescue (
          puts "**** Error when pulling data from site #{key}"
         break
        )
        site = Site.where(:name => key).first_or_create
        record(site,date ,data)
      end
      record_pulled_datetime(key, date)
    end
  end

end

def record_pulled_datetime(site_name, date)
  site = Site.where(:'name' => site_name).first
  pulled_time = PullTracker.where(:'site_id' => site.id).first
  
  if pulled_time.blank?
    pulled_time = PullTracker.new() 
    pulled_time.site_id = site.id
  end
  pulled_time.pulled_datetime = ("#{date.to_date} #{Time.now().strftime('%H:%M:%S')}")
  pulled_time.save
  puts "Recorded for :#{site_name}, Date: #{pulled_time.pulled_datetime}"
end

def record(site, date,data)

  (data['prescriptions'] || []).each do |key,prescription|

    pres_obs = Observation.where(:site_id => site.id,
      :definition_id => $prescription_id,
      :value_drug => Drug.check(key),
      :value_date => date
    ).first

    if pres_obs.blank?
      Observation.create({:site_id => site.id,
          :definition_id => $prescription_id,
          :value_numeric => prescription['bottles'],
          :value_drug => Drug.check(key),
          :value_date => date})
    else
      pres_obs.value_numeric = prescription['bottles']
      pres_obs.save
    end

    pres_to = Observation.where(:site_id => site.id,
      :definition_id => $drug_prescribed_id,
      :value_drug => Drug.check(key),
      :value_date => date
    ).first

    if pres_to.blank?
      Observation.create({:site_id => site.id,
          :definition_id => $drug_prescribed_id,
          :value_numeric => prescription['total_patients'],
          :value_drug => Drug.check(key),
          :value_date => date})
    else
      pres_to.value_numeric = prescription['total_patients']
      pres_to.save
    end
  end

  (data['dispensations'] || []).each do |key,dispensation|
    disp_obs = Observation.where(:site_id => site.id,
      :definition_id => $dispensation_id,
      :value_drug => Drug.check(key),
      :value_date => date
    ).first

    if disp_obs.blank?
      Observation.create({:site_id => site.id,
          :definition_id => $dispensation_id,
          :value_numeric => dispensation['bottles'],
          :value_drug => Drug.check(key),
          :value_date => date})
    else
      disp_obs.value_numeric = dispensation['bottles']
      disp_obs.save
    end

    disp_to = Observation.where(:site_id => site.id,
      :definition_id => $drug_given_to_id,
      :value_drug => Drug.check(key),
      :value_date => date
    ).first

    if disp_to.blank?
      Observation.create({:site_id => site.id,
          :definition_id => $drug_given_to_id,
          :value_numeric => dispensation['total_patients'],
          :value_drug => Drug.check(key),
          :value_date => date})
    else
      disp_to.value_numeric = dispensation['total_patients']
      disp_to.save
    end
  end

  (data['relocations'] || []).each do |key,relocation|
    next if relocation["relocated"] == 0
    relocation_obs = Observation.where(:site_id => site.id,
      :definition_id => $relocation_id,
      :value_drug => Drug.check(key),
      :value_date => date
    ).first

    if relocation_obs.blank?
      Observation.create({:site_id => site.id,
          :definition_id => $relocation_id,
          :value_numeric => relocation['relocated'],
          :value_drug => Drug.check(key),
          :value_date => date})
    else
      relocation_obs.value_numeric = relocation['relocated']
      relocation_obs.save
    end

  end

  (data['stock_level'].keys || []).each do |drug|

    data['stock_level'][drug].each do |key, value|
      $definition_id = Definition.where(:name => key).first.id
      if value.class.to_s == "Array"

        if value.first.class.to_s == "Array"

          value.each do |val|

            pills = val[0]
            date_of_count = val[1]
            value_text = val[2] if val[2].present?
            next if date_of_count.blank?
            stock_obs = Observation.where(:site_id => site.id,
              :definition_id => $definition_id,
              :value_drug => Drug.check(drug),
              :value_date => date_of_count
            ).first
            if stock_obs.blank?
              Observation.create({:site_id => site.id,
                  :definition_id => $definition_id,
                  :value_numeric => pills,
                  :value_drug => Drug.check(drug),
                  :value_text => value_text,
                  :value_date => date_of_count})
            else
              stock_obs.value_numeric = pills
              stock_obs.save
            end
          end
        else
          pills = value[0]
          date_of_count = value[1]
          next if date_of_count.blank?
          stock_obs = Observation.where(:site_id => site.id,
            :definition_id => $definition_id,
            :value_drug => Drug.check(drug),
            :value_date => date_of_count
          ).first
          if stock_obs.blank?
            Observation.create({:site_id => site.id,
                :definition_id => $definition_id,
                :value_numeric => pills,
                :value_drug => Drug.check(drug),
                :value_date => date_of_count})
          else
            stock_obs.value_numeric = pills
            stock_obs.save
          end
        end
      else

        stock_single_obs = Observation.where(:site_id => site.id,
          :definition_id => $definition_id,
          :value_drug => Drug.check(drug),
          :value_date => date
        ).first
        if stock_single_obs.blank?
          Observation.create({:site_id => site.id,
              :definition_id => $definition_id,
              :value_numeric => value,
              :value_drug => Drug.check(drug),
              :value_date => date})
        else
          stock_single_obs.value_numeric = value
          stock_single_obs.save
        end
      end
    end
  end

end

start
