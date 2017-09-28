require 'rest_client'
class HomeController < ApplicationController
  def index
    @sites = Site.where(:active => true)
  end

  def graph

    @days = []
    start = Date.today - 6.days
    (0..6).each do |i|
      @days << (start + i.days ).strftime('%A')
    end
    @pres_trend, @disp_trend, @rel_trend = aggregate()
    @drug_pres_trend, @drug_disp_trend, @drug_rel_trend = drug()

  end

  def site(days)

    site = Site.order("RAND()").first(1).first
    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id

    start = Date.today - 6.days
    end_date = Date.today
    highest_frequencies = Observation.find_by_sql("SELECT DISTINCT value_drug, SUM(value_numeric) AS amounts FROM observations "+
        " WHERE definition_id in (#{prescription_id}, #{dispensation_id}) AND value_date BETWEEN #{start} AND "+
        "  #{end_date} AND site_id = #{site.id} order by amounts DESC LIMIT 5").collect{|x| x.value_drug}

    prescriptions = Observation.where(:site_id => site.id,:value_drug => highest_frequencies,
      :definition_id => prescription_id,
      :value_date => start..end_date).order("value_date asc")

    dispensations = Observation.where(:site_id => site.id,:value_drug => highest_frequencies,
      :definition_id => dispensation_id,
      :value_date => start..end_date).order("value_date asc")

    disp_line,pres_line,disp_pie,pres_pie = graph_data_sorter(dispensations,prescriptions,days)

    data = {"dispensation_line" => disp_line,"dispensation_pie" => disp_pie,
      "prescription_line" => pres_line,"prescription_pie" => pres_pie}

    return [data,site.name]

  end

  def drug()

    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id
    relocation_id = Definition.where(:name => "relocation").first.id
    defns = [prescription_id,dispensation_id, relocation_id]
    start = Date.today - 30.days
    end_date = Date.today
    pres_trend = {}
    disp_trend = {}
    rel_trend = {}

    highest_frequencies = Observation.find_by_sql("SELECT DISTINCT value_drug, SUM(value_numeric) AS amounts FROM observations "+
        " WHERE definition_id in (#{prescription_id}) AND value_date BETWEEN '#{start}' AND "+
        "  '#{end_date}' GROUP BY value_drug ORDER BY amounts DESC LIMIT 10").collect{|x| x.value_drug}


    obs = Observation.find(:all, :conditions => ["definition_id in (?) AND value_drug in (?) AND value_date >= ? AND value_date <= ?",
        defns,highest_frequencies, start, end_date], :order =>"value_date asc")

    (obs || []).each do |record|


      if record.definition_id == prescription_id
        pres_trend[record.get_short_form].blank? ? pres_trend[record.get_short_form] = [[record.value_date,record.value_numeric]] : pres_trend[record.get_short_form] << [record.value_date,record.value_numeric]

      elsif record.definition_id == dispensation_id
        disp_trend[record.get_short_form].blank? ? disp_trend[record.get_short_form] = [[record.value_date,record.value_numeric]] : disp_trend[record.get_short_form] << [record.value_date,record.value_numeric]

      elsif record.definition_id == relocation_id
        rel_trend[record.get_short_form].blank? ? rel_trend[record.get_short_form] = [[record.value_date,record.value_numeric]] : rel_trend[record.get_short_form] << [record.value_date,record.value_numeric]
      end
    end

    return pres_trend, disp_trend, rel_trend


  end

  def aggregate()

    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id
    relocation_id = Definition.where(:name => "relocation").first.id
    defns = [prescription_id,dispensation_id, relocation_id]
    start = Date.today - 6.days
    end_date = Date.today
    pres_trend = {}
    disp_trend = {}
    rel_trend = {}

    obs = Observation.find_by_sql("SELECT value_date, definition_id, value_drug, SUM(value_numeric) AS value_numeric
                                  FROM observations where definition_id in (#{defns.join(',')}) and value_date >= '#{start}'
                                  AND value_date <= '#{end_date}' GROUP BY definition_id, value_date,value_drug
                                  ORDER BY value_date ASC")

    (obs || []).each do |record|


      if record.definition_id == prescription_id
        pres_trend[record.get_short_form].blank? ? pres_trend[record.get_short_form] = [[record.value_date,record.value_numeric]] : pres_trend[record.get_short_form] << [record.value_date,record.value_numeric]

      elsif record.definition_id == dispensation_id
        disp_trend[record.get_short_form].blank? ? disp_trend[record.get_short_form] = [[record.value_date,record.value_numeric]] : disp_trend[record.get_short_form] << [record.value_date,record.value_numeric]

      elsif record.definition_id == relocation_id
        rel_trend[record.get_short_form].blank? ? rel_trend[record.get_short_form] = [[record.value_date,record.value_numeric]] : rel_trend[record.get_short_form] << [record.value_date,record.value_numeric]
      end
    end

    return pres_trend, disp_trend, rel_trend
  end

  def graph_data_sorter(dispensations, prescriptions, days = nil)
    dispensations_pie = Hash.new(0)
    prescriptions_pie = Hash.new(0)
    dispensations_line = {}
    prescriptions_line = {}

    (dispensations || []).each do |dispensation|
      dispensations_pie[dispensation.value_drug] += dispensation.value_numeric
      if dispensations_line[dispensation.value_drug].blank?
        dispensations_line[dispensation.value_drug] = [0,0,0,0,0,0,0]
        index = days.index(dispensation.value_date.strftime('%A'))
        dispensations_line[dispensation.value_drug][index] = dispensation.value_numeric
      else
        index = days.index(dispensation.value_date.strftime('%A'))
        dispensations_line[dispensation.value_drug][index] = dispensation.value_numeric
      end
    end

    (prescriptions || []).each do |prescription|
      prescriptions_pie[prescription.value_drug] += prescription.value_numeric
      if prescriptions_line[prescription.value_drug].blank?
        prescriptions_line[prescription.value_drug] = [0,0,0,0,0,0,0]
        index = days.index(prescription.value_date.strftime('%A'))
        prescriptions_line[prescription.value_drug][index] = prescription.value_numeric
      else
        index = days.index(prescription.value_date.strftime('%A'))
        prescriptions_line[prescription.value_drug][index] = prescription.value_numeric
      end
    end

    return [dispensations_line,prescriptions_line,dispensations_pie,prescriptions_pie]
  end

  def graph_sorter(dispensations, prescriptions)
    dispensations_pie = Hash.new(0)
    prescriptions_pie = Hash.new(0)
    dispensations_line = {}
    prescriptions_line = {}

    (dispensations || []).each do |dispensation|
      dispensations_pie[dispensation.value_drug] += dispensation.value_numeric
      if dispensations_pie[dispensation.value_drug].blank?
        dispensations_line[dispensation.value_drug] = [0,0,0,0,0,0,0]
        index = days.index(dispensation.value_date.strftime('%A'))
        dispensations_line[dispensation.value_drug][index] = dispensation.value_numeric
      else
        index = days.index(dispensation.value_date.strftime('%A'))
        dispensations_line[dispensation.value_drug][index] = dispensation.value_numeric
      end
    end

    (prescriptions || []).each do |prescription|
      prescriptions_pie[prescription.value_drug] += prescription.value_numeric
      if prescriptions_line[prescription.value_drug].blank?
        prescriptions_line[prescription.value_drug] =[]
        prescriptions_line[prescription.value_drug] << prescription.value_numeric
      else
        prescriptions_line[prescriptione.value_drug] << prescription.value_numeric
      end
    end

    return [dispensations_line,prescriptions_line,dispensations_pie,prescriptions_pie]
  end

  def notices
    render :layout => false
  end

  def low_stock
    render :layout => false
  end

  def overstock
    render :layout => false
  end
  def ajax_burdens
    @sites = []
    new_notices_by_site = {}
    notices_under_investigation_by_site = {}
    new_state = Definition.find_by_name("new").id
    investigating = Definition.find_by_name("Investigating").id
    new_notices = Observation.find_by_sql("SELECT * FROM observations INNER JOIN states
     USING(observation_id) WHERE state=#{new_state} ")

    new_notices.each do |notice|
      site_id = notice.site_id
      new_notices_by_site[site_id] = {} if new_notices_by_site[site_id].blank?
      new_notices_by_site[site_id]["count"] = 0 if new_notices_by_site[site_id]["count"].blank?
      new_notices_by_site[site_id]["count"]+=1
    end

    notices_under_investigation = Observation.find_by_sql("SELECT * FROM observations INNER JOIN states
     USING(observation_id) WHERE state=#{investigating} ")

    notices_under_investigation.each do |notice|
      site_id = notice.site_id
      notices_under_investigation_by_site[site_id] = {} if notices_under_investigation_by_site[site_id].blank?
      notices_under_investigation_by_site[site_id]["count"] =  0 if notices_under_investigation_by_site[site_id]["count"].blank?
      notices_under_investigation_by_site[site_id]["count"] += 1
    end

    Site.all.each do |source|
      site = {
        'region' => source["region"],
        'x' => source["x"],
        'y' =>source["y"],
        'name' => source["name"],
        'proportion' => (new_notices_by_site[source.id]["count"] rescue 0),
        'new' => (new_notices_by_site[source.id]["count"] rescue 0),
        'investigating' => (notices_under_investigation_by_site[source.id]["count"] rescue 0)
      }

      @sites << site
    end

    render :json => @sites.to_json

  end

  def ajax_low_stock
    @sites = {"sites" => []}

    Site.all.each do |source|

      site = {
        'region' => source["region"],
        'x' => source["x"],
        'y' =>source["y"],
        'name' => source["name"],
        'proportion' => 0
      }

      @sites['sites'] << site
    end

    render :json => @sites.to_json
  end

  def ajax_high_stock
    @sites = []

    defn_set = Definition.find(:all, :conditions => ["name in (?)", ['Supervision Verification']]).collect { |x| x.id }

    obs = Observation.find_by_sql("SELECT DISTINCT value_drug, site_id FROM observations WHERE voided = 0
                                    AND definition_id IN (#{defn_set.join(',')}) GROUP BY site_id, value_drug")

    @locations = {}
    (obs || []).each do |drugs|
      month_of_stock = Observation.calculate_month_of_stock(drug.value_drug, drug.site_id)
      @locations[drugs.site.name] = [] if @locations[drugs.site.name].blank?
      @locations[drugs.site.name] << {drug.value_drug => month_of_stock}
    end

    sites = Site.find(:all, :conditions => ["name in (?)", @locations.keys])
    (sites || []).each do |source|

      site = {
        'region' => source["region"],
        'x' => source["x"],
        'y' =>source["y"],
        'name' => source["name"],
        'proportion' => 0
      }

      @sites << site
    end

    render :json => @sites.to_json
  end

  def manage_notices
    @site_name = params[:site_name]
    site_id = Site.find_by_name(params[:site_name]).site_id
    new_state = Definition.find_by_name("new").id
    new_state = Definition.find_by_name("new").id
    investigating = Definition.find_by_name("Investigating").id
    @new_notices = Observation.find_by_sql("SELECT * FROM observations INNNER JOIN states
     USING(observation_id) WHERE state=#{new_state} AND site_id=#{site_id}")

    @under_investigations = Observation.find_by_sql("SELECT * FROM observations INNNER JOIN states
     USING(observation_id) WHERE state=#{investigating} AND site_id=#{site_id}")

    @resolved = Observation.find_by_sql("SELECT * FROM observations INNNER JOIN states
     USING(observation_id) WHERE state='Resolved' AND site_id=#{site_id}")
    
  end

  def map_main
    @sites = []
    sites = Site.find(:all, :conditions => ["active =?", true])
    (sites || []).each do |source|
      notices = ReportTool.get_notices_summary(source.id)
      site = {
        'x' => source["x"],
        'y' =>source["y"],
        'name' => source["name"],
        'proportion' => 0,
        'new_notices' => notices["New"],
        "not_investigating" => notices["Investigating"]
      }

      @sites << site
    end
    # raise @sites.inspect
    render :layout => false
  end

  def dashboard
    @sites = Site.where(:active => 1)
    render :layout => false
  end

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

        create_or_update_mysql_from_couch(couch_data)
      end rescue nil
    end

    render :text => couch_data.to_json and return
  end

  def create_or_update_mysql_from_couch(data)
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
    sites = Site.where(:active => 1)
    (sites || []).each do |site|
      puts "calculating for site : #{site.name}"
      (drugs || []).each do |drug|
        month_of_stock = Observation.calculate_month_of_stock(drug.value_drug, site.id)

        unless (month_of_stock.is_a? String ||  month_of_stock.nan? || month_of_stock.to_s.downcase == "infinity")
          puts "Month of stock : #{month_of_stock} for drug #{drug.value_drug} "
          Observation.create({:site_id => site.id,
              :definition_id => month_of_stock_defn,
              :value_numeric => month_of_stock.to_f.round(3),
              :value_drug => drug.value_drug,
              :value_date => Date.today})

        end
      end
    end
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

end


