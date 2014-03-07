class Observation < ActiveRecord::Base
  set_primary_key :observation_id
  belongs_to :site, :foreign_key => :site_id
  belongs_to :definition, :foreign_key => :definition_id
  validates_presence_of :site_id
  validates_presence_of :definition_id

  def self.drug_stock_out_predictions
    
    rates = self.daily_drug_dispensation_rates

    result = {}
    self.find_by_sql(
      "SELECT site_id, value_drug AS drug_name, value_date AS date, value_numeric AS stock_level FROM observations
        WHERE definition_id = (SELECT definition_id FROM definitions WHERE name = 'Stock' LIMIT 1)
        GROUP BY site_id, value_drug"
    ).each do |obs|

      result[obs.site_id] = {} if result[obs.site_id].blank?
      if (rates[obs.site_id][obs.drug_name].blank? rescue true) || rates[obs.site_id][obs.drug_name].to_i == 0
          result[obs.site_id][obs.drug_name] = nil
          next
      end
      
      result[obs.site_id][obs.drug_name] = (obs.date.to_date +
          (obs.stock_level.to_i/rates[obs.site_id][obs.drug_name].to_f).round(0).days) 
    end
  
    return result
  end

  def self.daily_drug_dispensation_rates

    return  self.find_by_sql(
      "SELECT site_id, value_drug AS drug_name, ROUND(AVG(value_numeric)) AS rate FROM observations
        WHERE definition_id = (SELECT definition_id FROM definitions WHERE name = 'Dispensation' LIMIT 1)
        GROUP BY site_id, value_drug"
    ).inject({}){|result, obs|
      result[obs.site_id] = {} if result[obs.site_id].blank?; result[obs.site_id][obs.drug_name] = obs.rate; result
    }    
  end
  
end
