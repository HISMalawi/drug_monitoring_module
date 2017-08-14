require 'couchrest_model'
class Observation < CouchRest::Model::Base
  #set_primary_key :observation_id
  #belongs_to :site, :foreign_key => :site_id
  #belongs_to :definition, :foreign_key => :definition_id
  #belongs_to :drug, :foreign_key => :value_drug
  #belongs_to :drug_cms, :foreign_key => :value_drug
  #belongs_to :user, :foreign_key => :creator
  #validates_presence_of :site_id
  #validates_presence_of :definition_id

  property :observation_id, Integer
  property :site_id, Integer
  property :definition_id, Integer #value_numeric
  property :value_numeric, Float #value_date
  property :value_date, Date #value_text
  property :value_text, String #value_drug
  property :value_drug, Integer #voided

  def get_short_form
    DrugCms.where(:drug_inventory_id => self.value_drug).first.short_name rescue self.value_drug
  end

  def definition_name
    self.definition.name
  end

  def self.drug_stock_out_predictions(type = 'calculated')
    # ** This method calculates estimated stock out dates for drugs per each site
    # ** Based on daily consumption/dispensation rate
    # ** Developer   : KENNETH KAPUNDI

    rates = self.daily_drug_dispensation_rates

    result = {}

    query_for_prescribed = "SELECT MAX(f.value_numeric) FROM observations f WHERE f.definition_id =
                                      (SELECT definition_id FROM definitions WHERE name = 'Total prescribed' LIMIT 1)
                                      AND f.site_id = obs.site_id
                                      AND f.value_drug = obs.value_drug
                             ORDER BY observation_id DESC LIMIT 1"

    query_for_dispensed = "SELECT MAX(o1.value_numeric) FROM observations o1 WHERE o1.definition_id =
                                      (SELECT definition_id FROM definitions WHERE name = 'Total dispensed' LIMIT 1)
                                      AND o1.site_id = obs.site_id
                                      AND o1.value_drug = obs.value_drug
                            ORDER BY observation_id DESC LIMIT 1"

    total_dispensed_daily = "SELECT SUM(od.value_numeric) FROM observations od WHERE od.definition_id =
                                      (SELECT definition_id FROM definitions WHERE name = 'Dispensation' LIMIT 1)
                                      AND od.site_id = obs.site_id
                                      AND od.value_drug = obs.value_drug
                                      AND od.value_date >= obs.value_date"

    later_supervisions = "SELECT SUM(od.value_numeric) FROM observations od WHERE od.definition_id =
                                      (SELECT definition_id FROM definitions WHERE name = 'Supervision verification' LIMIT 1)
                                      AND od.site_id = obs.site_id
                                      AND od.value_drug = obs.value_drug
                                      AND od.value_date >= obs.value_date"
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
                  (#{query_for_prescribed}) AS prescribed,
                  (obs.value_numeric - (#{total_dispensed_daily})) AS stock_level
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
      #result[site_name][obs.drug_name]["prescribed"] = obs.prescribed.blank? ? "Unknown" : obs.prescribed
      #result[site_name][obs.drug_name]["dispensed"] = (obs.dispensed.blank? ? "Unknown" : obs.dispensed)
      result[site_name][obs.drug_name]["stock_level"] = obs.stock_level.blank? ? "Unknown" : obs.stock_level
      result[site_name][obs.drug_name]["rate"] = rates[obs.site_id][obs.drug_name].blank? ? "Unknown" :
        rates[obs.site_id][obs.drug_name]
      result[site_name][obs.drug_name]["stockout_date"] = result[site_name][obs.drug_name]["stock_level"].to_i == 0 ? "No stock" :
        (obs.date.to_date + (obs.stock_level.to_i/rates[obs.site_id][obs.drug_name].to_f).round(0).days).strftime("%d %b, %Y")

    end

    return result
  end

  def self.daily_drug_dispensation_rates
    # ** This method calculates average consumption/dispensation rate
    # ** Of drugs per each site
    # ** Developer   : KENNETH KAPUNDI
=begin
    return  self.find_by_sql(
      "SELECT site_id, value_drug AS drug_name, ROUND(AVG(value_numeric)) AS rate FROM observations
        WHERE definition_id = (SELECT definition_id FROM definitions WHERE name = 'Dispensation' LIMIT 1)
        GROUP BY site_id, value_drug"
    ).inject({}){|result, obs|
      result[obs.site_id] = {} if result[obs.site_id].blank?; result[obs.site_id][obs.drug_name] = obs.rate; result
    }
=end
    date = Date.today ; result = {}

    stock_rate_defn = Definition.find_by_name("Drug rate").id
    obs = Observation.find_by_sql("SELECT value_numeric,site_id,value_drug FROM observations WHERE voided = 0
      AND definition_id = #{stock_rate_defn} AND value_date <= '#{date}'
      AND value_date = (SELECT MAX(value_date) FROM observations WHERE voided = 0
      AND definition_id = #{stock_rate_defn} AND value_date <= '#{date}')")

    (obs || []).each do |ob|
      result[ob.site_id] = {} if result[ob.site_id].blank?
      result[ob.site_id][ob.value_drug] = ob.value_numeric 
    end

    return result
  end

  def self.drug_dispensation_rates(drug, site_id = nil)
    # ** This method calculates average consumption/dispensation rate
    # ** Of a specific drug per each site

     return self.calculate_drug_rate(drug, site_id, Date.today)
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

  def self.dispensed(drug_name, date, unitQty=60)

    definition_id = Definition.find_by_name("Dispensation").id
    d = Observation.find(:last,
      :select => ["value_numeric"],
      :conditions => ["definition_id = ? AND value_drug = ? AND value_date = ?",
        definition_id, drug_name, date]).value_numeric.to_i rescue 0

    return (d/unitQty.to_f).round
  end

  def self.relocated(drug_name, date, unitQty = 60)

    definition_id = Definition.find_by_name("Relocation").id
    d = Observation.find(:last,
                         :select => ["value_numeric"],
                         :conditions => ["definition_id = ? AND value_drug = ? AND value_date = ?",
                                         definition_id, drug_name, date]).value_numeric.to_i rescue 0

    return (d/unitQty.to_f).round
  end

  def self.deliveries(site_id = 1, start_date = Date.today, end_date = Date.today, delivery_code = nil)

    definition_id = Definition.find_by_name("New Delivery").id
    result = {}
    if delivery_code.blank?

      result = Observation.find_by_sql(["SELECT value_date d, value_drug dr, value_numeric n, value_text t FROM observations
                                    WHERE site_id = #{site_id} AND definition_id = #{definition_id} AND (value_date BETWEEN (?) AND (?))
                                    GROUP BY value_drug, value_date", start_date.to_date, end_date.to_date]).inject({}){|r, o|
        r[o.d] = {} if !r.keys.include?(o.d); r[o.d][o.dr] = {} if !r[o.d].keys.include?(o.dr); r[o.d][o.dr]["value"] = o.n; r[o.d][o.dr]["code"] = o.t; r}
    else

      result = Observation.find_by_sql(["SELECT value_date d, value_drug dr, value_numeric n, value_text t FROM observations
                                    WHERE site_id = #{site_id} AND definition_id = #{definition_id} AND value_text = '#{delivery_code}'
                                    GROUP BY value_drug, value_date"]).inject({}){|r, o|
        r[o.d] = {} if !r.keys.include?(o.d); r[o.d][o.dr] = {} if !r[o.d].keys.include?(o.dr); r[o.d][o.dr]["value"] = o.n; r[o.d][o.dr]["code"] = o.t; r}
    end

    return result
  end

  def self.site_by_code(code)
    check = Observation.find_by_value_text(code)
    site_id = check.present? ? check.site_id : -1
    return site_id
  end

  def self.max_dispensed(drug = nil, site_id = nil)

    dispensation_id = Definition.where(:name => "dispensation").first.id

    if drug.blank?
      if site_id.blank?
        return  self.find_by_sql(
            "SELECT value_drug,MAX(value_numeric) AS value,site_id FROM observations
        WHERE definition_id = #{dispensation_id} GROUP BY value_drug, site_id"
        ).inject({}){|result, obs|
          result[obs.site_id] = [] if result[obs.site_id].blank?; result[obs.site_id] << {obs.value_drug => obs.value}; result
        }
      else
        return  self.find_by_sql(
        "SELECT value_drug,MAX(value_numeric) AS value FROM observations
        WHERE definition_id = #{dispensation_id} AND site_id = #{site_id}
        GROUP BY value_drug"
        ).inject({}){|result, obs|
          result[obs.value_drug] = {} if result[obs.site_id].blank?; result[obs.value_drug] = obs.value; result
        }
      end
    else
      if site_id.blank?
        return  self.find_by_sql(
        "SELECT MAX(value_numeric) AS value,site_id FROM observations
        WHERE definition_id = #{dispensation_id} AND value_drug = '#{drug}'
        GROUP BY site_id"
        ).inject({}){|result, obs|
          result[obs.site_id] = obs.value; result
        }
      else
        return  self.find_by_sql(
            "SELECT MAX(value_numeric) AS value FROM observations
        WHERE definition_id = #{dispensation_id} AND value_drug = '#{drug}'
        AND site_id = #{site_id}").first.value
      end
    end
  end

  def self.min_dispensed(drug = nil, site = nil)
    dispensation_id = Definition.where(:name => "dispensation").first.id

    if drug.blank?
      if site_id.blank?
        return  self.find_by_sql(
            "SELECT value_drug,MIN(value_numeric) AS value,site_id FROM observations
        WHERE definition_id = #{dispensation_id} GROUP BY value_drug, site_id"
        ).inject({}){|result, obs|
          result[obs.site_id] = [] if result[obs.site_id].blank?; result[obs.site_id] << {obs.value_drug => obs.value}; result
        }
      else
        return  self.find_by_sql(
            "SELECT value_drug,MIN(value_numeric) AS value FROM observations
        WHERE definition_id = #{dispensation_id} AND site_id = #{site_id}
        GROUP BY value_drug"
        ).inject({}){|result, obs|
          result[obs.value_drug] = {} if result[obs.site_id].blank?; result[obs.value_drug] = obs.value; result
        }
      end
    else
      if site_id.blank?
        return  self.find_by_sql(
            "SELECT MIN(value_numeric) AS value,site_id FROM observations
        WHERE definition_id = #{dispensation_id} AND value_drug = '#{drug}'
        GROUP BY site_id"
        ).inject({}){|result, obs|
          result[obs.site_id] = obs.value; result
        }
      else
        return  self.find_by_sql(
            "SELECT MIN(value_numeric) AS value FROM observations
        WHERE definition_id = #{dispensation_id} AND value_drug = '#{drug}'
        AND site_id = #{site_id}").first.value
      end
    end
  end

  def self.total_dispensed( date = Date.today, drug =nil, site_id =nil)
    dispensation_id = Definition.where(:name => "Dispensation").first.id

    if drug.blank?
      if site_id.blank?
        return  self.find_by_sql(
            "SELECT value_drug,MAX(value_numeric) AS value,site_id FROM observations
        WHERE definition_id = #{dispensation_id} AND value_date <= '#{date}'
        GROUP BY value_drug, site_id"
        ).inject({}){|result, obs|
          result[obs.site_id] = [] if result[obs.site_id].blank?; result[obs.site_id] << {obs.value_drug => obs.value}; result
        }
      else
        return  self.find_by_sql(
            "SELECT value_drug,MAX(value_numeric) AS value FROM observations
        WHERE definition_id = #{dispensation_id}  AND value_date <= '#{date}' AND site_id = #{site_id}
        GROUP BY value_drug"
        ).inject({}){|result, obs|
          result[obs.value_drug] = {} if result[obs.site_id].blank?; result[obs.value_drug] = obs.value; result
        }
      end
    else
      if site_id.blank?
        return  self.find_by_sql(
            "SELECT MAX(value_numeric) AS value,site_id FROM observations
        WHERE definition_id = #{dispensation_id} AND value_drug = #{drug}
         AND value_date >= '#{date}' GROUP BY site_id"
        ).inject({}){|result, obs|
          result[obs.site_id] = obs.value; result
        }
      else
        return  self.find_by_sql(
            "SELECT SUM(value_numeric) AS value FROM observations
        WHERE definition_id = #{dispensation_id} AND value_drug = #{drug}
        AND site_id = #{site_id} ").first.value
      end
    end
  end

  def self.total_removed( date = Date.today, drug =nil, site_id =nil)
    removed_id = Definition.where(:name => "Total Removed").first.id

    if drug.blank?
      if site_id.blank?
        return  self.find_by_sql(
            "SELECT value_drug,MAX(value_numeric) AS value,site_id FROM observations
        WHERE definition_id = #{removed_id} AND value_date <= '#{date}'
        GROUP BY value_drug, site_id"
        ).inject({}){|result, obs|
          result[obs.site_id] = [] if result[obs.site_id].blank?; result[obs.site_id] << {obs.value_drug => obs.value}; result
        }
      else
        return  self.find_by_sql(
            "SELECT value_drug,MAX(value_numeric) AS value FROM observations
        WHERE definition_id = #{removed_id}  AND value_date <= '#{date}' AND site_id = #{site_id}
        GROUP BY value_drug"
        ).inject({}){|result, obs|
          result[obs.value_drug] = {} if result[obs.site_id].blank?; result[obs.value_drug] = obs.value; result
        }
      end
    else
      if site_id.blank?
        return  self.find_by_sql(
            "SELECT MAX(value_numeric) AS value,site_id FROM observations
        WHERE definition_id = #{removed_id} AND value_drug = #{drug}
         AND value_date <= '#{date}' GROUP BY site_id"
        ).inject({}){|result, obs|
          result[obs.site_id] = obs.value; result
        }
      else
        return  self.find_by_sql(
            "SELECT SUM(value_numeric) AS value FROM observations
        WHERE definition_id = #{removed_id} AND value_drug = #{drug}
        AND site_id = #{site_id} AND value_date >='#{date}'").first.value
      end
    end
  end

  def self.calculate_stock_level(drug, site_id, date = Date.today )
=begin
    total_delivered_defn = Definition.find_by_name("supervision verification").id

    obs = Observation.find_by_sql("SELECT value_numeric, MAX(value_date) as date FROM observations WHERE voided = 0
                                              AND definition_id = #{total_delivered_defn} AND value_drug = #{drug}
                                              AND site_id = #{site_id} ORDER BY value_date").first

    total_delivered = obs.value_numeric

    dispensed_total = Observation.total_dispensed(obs.date,drug,site_id)

    removed_total = Observation.total_removed(obs.date,drug,site_id)

    stock_level = total_delivered.to_i - (dispensed_total.to_i + removed_total.to_i)

    if stock_level < 0
      d = DrugCms.find(drug).short_name
      notice = "negative stock for #{d}"
      Observation.create_notification(site_id,obs.date, notice, drug)
    end

    return stock_level < 0 ? 0 : stock_level
=end
    stock_level_defn = Definition.find_by_name("Stock level").id
    obs = Observation.find_by_sql("SELECT value_numeric FROM observations WHERE voided = 0
          AND definition_id = #{stock_level_defn} AND value_drug = #{drug}
          AND site_id = #{site_id} AND value_date <= '#{date}'
          AND value_date = (SELECT MAX(value_date) FROM observations WHERE voided = 0
          AND definition_id = #{stock_level_defn} AND value_drug = #{drug}
          AND site_id = #{site_id} AND value_date <= '#{date}')")

    return obs.first.value_numeric rescue 0
  end

  def self.calculate_month_of_stock(drug, site_id, unitQty = 60)

    stock_level = Observation.calculate_stock_level(drug, site_id).to_i

    dispensation_rate = Observation.drug_dispensation_rates(drug,site_id)

    if dispensation_rate.blank?
      return "Unknown"

    else
      #consumption_rate = (dispensation_rate.to_f * 0.5) * (60.0/unitQty.to_f).round
      consumption_rate = ((30 * dispensation_rate)/unitQty)
      expected = (stock_level/ unitQty.to_f).round

      month_of_stock = (expected/ consumption_rate) rescue 0

      if month_of_stock <= 2.0
        notice = "#{DrugCms.find(drug).short_name} stock running low"
        Observation.create_notification(site_id,Date.today,notice,drug)
      elsif month_of_stock >= 7.0
        notice = "#{Site.find(site_id).name} has excess #{DrugCms.find(drug).short_name} stock"
        Observation.create_notification(site_id,Date.today,notice,drug)
      end

      return month_of_stock
    end

  end

  def self.create_notification(site_id, date, notice, drug)

    notice_defn = Definition.find_by_name("Notice")
    state_defn = Definition.find_by_name("New")
    states = Definition.where(:name => ["new", "investigating"]).collect{|x| x.id}

    obs = State.joins(:observation).where("observations.site_id" => site_id,
                            "observations.value_drug" => drug,
                            "observations.value_text" => notice,
                            :state => states
    ).first

    if obs.blank?
      obs = Observation.create(:site_id => site_id,
                               :definition_id => notice_defn.id,
                               :value_drug => drug,
                               :value_date => date,
                               :value_text => notice
      )
      state = State.create(:observation_id => obs.id, :state => state_defn.id)
    end
  end

  def self.day_deliveries(site_id = 1, date = Date.today, unitQty=60)
    #This function gets the deliveries to a site on a particular day
    definition_id = Definition.find_by_name("New Delivery").id
    results = {}


      result = Observation.find_by_sql("SELECT value_date as date, value_drug, SUM(value_numeric) as value, value_text as code FROM observations
                                    WHERE site_id = #{site_id} AND definition_id = #{definition_id} AND value_date = '#{date.to_date}'
                                    GROUP BY value_drug, value_date, value_text")

      (result || []).each do |record|

        results[DrugCms.find(record.value_drug).short_name] = [] if results[DrugCms.find(record.value_drug).short_name].blank?
        results[DrugCms.find(record.value_drug).short_name] <<  {"value" => (record.value.to_i/unitQty.to_f).round, "code" => record.code}
      end

    return results
  end

  def self.deliveries_by_code(site_id, code, unitQty=60)
      #This function gets deliveries based on the delivery code
    definition_id = Definition.find_by_name("New Delivery").id
    results = []


    result = Observation.find_by_sql("SELECT value_date as date, value_drug, SUM(value_numeric) as value FROM observations
                                    WHERE site_id = #{site_id} AND definition_id = #{definition_id} AND value_text = '#{code}'
                                    GROUP BY value_drug, value_date")

    (result || []).each do |record|
      results <<  {"value" => (record.value.to_i/unitQty.to_f).round, "date" => record.date, "drug" => DrugCms.find(record.value_drug).short_name}
    end

    return results
  end


  def self.deliveries_in_range(site_id = 1, start_date = Date.today, end_date = Date.today, unitQty=60)
    #This function gets the deliveries to a site within a given range
    definition_id = Definition.find_by_name("New Delivery").id
    results = {}


    result = Observation.find_by_sql("SELECT value_date as date, value_drug, SUM(value_numeric) as value,
                                      value_text as code FROM observations WHERE site_id = #{site_id} AND
                                      definition_id = #{definition_id} AND value_date BETWEEN '#{start_date.to_date}'
                                      AND '#{end_date.to_date}'GROUP BY value_drug, value_date, value_text")

    (result || []).each do |record|

      results[DrugCms.find(record.value_drug).short_name] = [] if results[DrugCms.find(record.value_drug).short_name].blank?
      results[DrugCms.find(record.value_drug).short_name] <<  {"value" => (record.value.to_i/unitQty.to_f).round, "code" => record.code,
                                                            "date" => record.date}
    end

    return results
  end

  def drug_name
    self.drug.short_name
  end

  def creator_name
    self.user.username
  end
    
  def self.calculate_drug_rate(drug, site_id, date = Date.today )
    stock_rate_defn = Definition.find_by_name("Drug rate").id
    obs = Observation.find_by_sql("SELECT value_numeric FROM observations WHERE voided = 0
          AND definition_id = #{stock_rate_defn} AND value_drug = #{drug}
          AND site_id = #{site_id} AND value_date <= '#{date}'
          AND value_date = (SELECT MAX(value_date) FROM observations WHERE voided = 0
          AND definition_id = #{stock_rate_defn} AND value_drug = #{drug}
          AND site_id = #{site_id} AND value_date <= '#{date}')")

    return obs.first.value_numeric rescue 0
  end

end
