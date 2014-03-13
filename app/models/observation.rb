class Observation < ActiveRecord::Base
  set_primary_key :observation_id
  belongs_to :site, :foreign_key => :site_id
  belongs_to :definition, :foreign_key => :definition_id
  validates_presence_of :site_id
  validates_presence_of :definition_id

  def self.drug_stock_out_predictions(type = 'calculated')
    # ** This method calculates estimated stock out dates for drugs per each site
    # ** Based on daily consumption/dispensation rate
    # ** Developer   : KENNETH KAPUNDI
    
    rates = self.daily_drug_dispensation_rates

    result = {}

    query_for_prescribed = "SELECT o0.value_numeric FROM observations o0 WHERE o0.definition_id =
                                      (SELECT definition_id FROM definitions WHERE name = 'Total prescribed' LIMIT 1)
                                      AND o0.site_id = obs.site_id
                                      AND o0.value_drug = obs.value_drug
                                      AND o0.value_date = obs.value_date
                             ORDER BY observation_id DESC LIMIT 1"

    query_for_dispensed = "SELECT o1.value_numeric FROM observations o1 WHERE o1.definition_id =
                                      (SELECT definition_id FROM definitions WHERE name = 'Total dispensed' LIMIT 1)
                                      AND o1.site_id = obs.site_id
                                      AND o1.value_drug = obs.value_drug
                                      AND o1.value_date = obs.value_date
                             ORDER BY observation_id DESC LIMIT 1"
    
    if type == 'calculated'
      
      query_for_removed = "SELECT o2.value_numeric FROM observations o2 WHERE o2.definition_id =
                                      (SELECT definition_id FROM definitions WHERE name = 'Total removed' LIMIT 1)
                                      AND o2.site_id = obs.site_id
                                      AND o2.value_drug = obs.value_drug
                                      AND o2.value_date = obs.value_date
                                      ORDER BY observation_id DESC LIMIT 1"

      query_for_delivered = "SELECT o3.value_numeric FROM observations o3 WHERE o3.definition_id =
                                      (SELECT definition_id FROM definitions WHERE name = 'Total delivered' LIMIT 1)
                                      AND o3.site_id = obs.site_id
                                      AND o3.value_drug = obs.value_drug
                                      AND o3.value_date = obs.value_date
                                      ORDER BY observation_id DESC LIMIT 1"

      main_query = self.find_by_sql(
        "SELECT obs.site_id, obs.value_drug AS drug_name, obs.value_date AS date, 
                  (#{query_for_prescribed}) AS prescribed, (#{query_for_dispensed}) AS dispensed,
                  (SELECT ((#{query_for_delivered}) - COALESCE((#{query_for_dispensed}) + (#{query_for_removed}), 0))) AS stock_level
        FROM observations obs
                  WHERE obs.value_date =
                      (SELECT MAX(ob.value_date) FROM observations ob
                    WHERE ob.value_drug = obs.value_drug
                      AND ob.site_id = obs.site_id AND ob.definition_id = obs.definition_id)
                  AND definition_id = (SELECT definition_id FROM definitions WHERE name = 'Total delivered' LIMIT 1)
                  GROUP BY site_id, value_drug")
    
    else
      
      definition = (type == 'verified_by_clinic') ? "Clinic verification" : "Supervision verification"

      main_query = self.find_by_sql(
        "SELECT obs.site_id, obs.value_drug AS drug_name, obs.value_date AS date,
                  (#{query_for_prescribed}) AS prescribed, (#{query_for_dispensed}) AS dispensed,
                  obs.value_numeric AS stock_level
        FROM observations obs
                  WHERE obs.value_date =
                      (SELECT MAX(ob.value_date) FROM observations ob
                    WHERE ob.value_drug = obs.value_drug
                      AND ob.site_id = obs.site_id
                      AND ob.definition_id = obs.definition_id)                     
                  AND definition_id = (SELECT definition_id FROM definitions WHERE name = '#{definition}' LIMIT 1)
                  GROUP BY site_id, value_drug"
      )

    end
   
    main_query.each do |obs|
      
      site_name = Site.find(obs.site_id).name
      result[site_name] = {} if result[site_name].blank?
     
      result[site_name][obs.drug_name] = {}
       
      if (rates[obs.site_id][obs.drug_name].blank? rescue true) || rates[obs.site_id][obs.drug_name].to_i == 0
        result[site_name].delete(obs.drug_name)
        next
      end

      result[site_name][obs.drug_name]["date"] = obs.date.to_date
      result[site_name][obs.drug_name]["prescribed"] = obs.prescribed.blank? ? "Unknown" : obs.prescribed
      result[site_name][obs.drug_name]["dispensed"] = obs.dispensed.blank? ? "Unknown" : obs.dispensed
      result[site_name][obs.drug_name]["stock_level"] = obs.stock_level.blank? ? "Unknown" : obs.stock_level
      result[site_name][obs.drug_name]["rate"] = rates[obs.site_id][obs.drug_name].blank? ? "Unknown" :
        rates[obs.site_id][obs.drug_name]
      result[site_name][obs.drug_name]["stockout_date"] = result[site_name][obs.drug_name]["stock_level"].to_i == 0 ? "Not applicable" :
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

  def self.site_update_dates
    # ** This method pull dates each site data was updated
    # ** Developer  : KENNETH KAPUNDI

    result = {}
    self.find_by_sql("SELECT DISTINCT (site_id) FROm observations").map(&:site_id).each{|site_id|
      result[Site.find(site_id).name] = {}
      
      result[Site.find(site_id).name]["calculated"] =  self.find_by_sql("SELECT MAX(value_date) max_date FROM observations
            WHERE site_id = #{site_id}")[0]["max_date"].to_date.strftime("%d/%b/%Y") rescue "?"
      
      result[Site.find(site_id).name]["clinic"] = self.find_by_sql("SELECT MAX(value_date) max_date FROM observations
            WHERE definition_id = (SELECT definition_id FROM definitions WHERE name = 'Clinic verification')
             AND site_id = #{site_id}")[0]["max_date"].to_date.strftime("%d/%b/%Y") rescue "?"

      result[Site.find(site_id).name]["supervision"] = self.find_by_sql("SELECT MAX(value_date) max_date FROM observations
            WHERE definition_id = (SELECT definition_id FROM definitions WHERE name = 'Supervision verification')
             AND site_id = #{site_id}")[0]["max_date"].to_date.strftime("%d/%b/%Y") rescue "?"
    }
    return result
  end
  
end
