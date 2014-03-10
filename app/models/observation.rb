class Observation < ActiveRecord::Base
  set_primary_key :observation_id
  belongs_to :site, :foreign_key => :site_id
  belongs_to :definition, :foreign_key => :definition_id
  validates_presence_of :site_id
  validates_presence_of :definition_id

  def self.drug_stock_out_predictions
    # ** This method calculates estimated stock out dates for drugs per each site
    # ** Based on daily consumption/dispensation rate
    # ** Developer   : KENNETH KAPUNDI
    
    rates = self.daily_drug_dispensation_rates

    result = {}
    self.find_by_sql(
      "SELECT site_id, value_drug AS drug_name, value_date AS date, value_numeric AS stock_level FROM observations
        WHERE definition_id = (SELECT definition_id FROM definitions WHERE name = 'Stock' LIMIT 1)
        GROUP BY site_id, value_drug ORDER BY date"
    ).each do |obs|
      
      site_name = Site.find(obs.site_id).name
      result[site_name] = {} if result[site_name].blank?
      result[site_name][obs.drug_name] = {}
      
      if (rates[obs.site_id][obs.drug_name].blank? rescue true) || rates[obs.site_id][obs.drug_name].to_i == 0
        
        result[site_name].delete(obs.drug_name)
        next
      end 

      result[site_name][obs.drug_name]["stock_level"] = obs.stock_level.blank? ? "Unknown" : obs.stock_level
      result[site_name][obs.drug_name]["rate"] = rates[obs.site_id][obs.drug_name].blank? ? "Unknown" :
        rates[obs.site_id][obs.drug_name]
      result[site_name][obs.drug_name]["stockout_date"] = result[site_name][obs.drug_name]["stock_level"].to_i == 0 ? "No applicable" :
        (obs.date.to_date + (obs.stock_level.to_i/rates[obs.site_id][obs.drug_name].to_f).round(0).days).strftime("%d %b, %Y")
      
    end
  
    return result
  end

  def self.daily_drug_dispensation_rates
    # ** This method calculates average consumption/dispensation rate
    # ** Of drugs per each site
    # ** Developer   : KENNETH KAPUNDI
    
    return  self.find_by_sql(
      "SELECT site_id, value_drug AS drug_name, ROUND(AVG(value_numeric)) AS rate FROM observations
        WHERE definition_id = (SELECT definition_id FROM definitions WHERE name = 'Dispensation' LIMIT 1)
        GROUP BY site_id, value_drug"
    ).inject({}){|result, obs|
      result[obs.site_id] = {} if result[obs.site_id].blank?; result[obs.site_id][obs.drug_name] = obs.rate; result
    }    
  end
  
end
