class ReportController < ApplicationController

  def index
    @lastdate = Observation.find_by_sql("SELECT site_id, max(value_date) as max_date FROM drug_mgmt.observations
                                        group by site_id order by max_date asc ;").first.max_date rescue nil
  end

  def site_list
    @sites = Site.all
  end

  def report_menu
    @sites = Site.all_sites
    @drugs = drugs

  end

  def process_report

    start_date = params[:start_date].to_date.strftime("%Y-%m-%d") rescue "nil"
    end_date = params[:end_date].to_date.strftime("%Y-%m-%d") rescue nil

    case params[:report_type]
    when "drug stock report"
      drug = params[:drug]
      redirect_to :action => 'drug_report',:drug => drug, :start_date => start_date, :end_date => end_date
    when "drug utilization report"
      drug = params[:drug]
      redirect_to :action => 'drug_utilization_report',:drug => drug, :start_date => start_date, :end_date => end_date
    when "aggregate report"
      redirect_to :action => 'aggregate_report', :start_date => start_date, :end_date => end_date
    when "site report"
      site = params[:site_name]
      redirect_to :action => 'site_report', :site => site, :start_date => start_date, :end_date => end_date
    when "stock movement"
      redirect_to :action => 'stock_out_estimates', :start_date => start_date, :end_date => end_date, 
        :type => "verified_by_supervision", :name => "stock_movement", :site_name => params[:site_name]
    when "delivery report"
      redirect_to :action => 'delivery_report', :start_date => start_date, :end_date => end_date,
        :name => "delivery_report", :site_name => params[:site_name], :delivery_code => params[:delivery_code]
    end
  end

  def site_report
    @title = "Site Report For #{params[:site]}"

    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id
    relocation_id = Definition.where(:name => "relocation").first.id
    drug_given_to_id = Definition.where(:name => "People who received drugs").first.id
    defns = [prescription_id,dispensation_id, relocation_id, drug_given_to_id]
    site = Site.find_by_name(params[:site])

    @values = {}
    obs = Observation.find(:all,:order => "value_date DESC",
      :conditions => ["definition_id in (?) AND site_id = ? AND value_date >= ? AND value_date <= ?",
        defns,site.id,params[:start_date],params[:end_date]])
    (obs || []).each do |record|

      @values[record.value_date] = {} unless !@values[record.value_date].blank?
      @values[record.value_date][record.get_short_form] = {"prescription" => 0, "dispensation" => 0, "relocation" => 0, "ppo_who_received_drugs" => 0} unless !@values[record.value_date][record.get_short_form].blank?
      if record.definition_id == prescription_id
        @values[record.value_date][record.get_short_form]["prescription"] = (@values[record.value_date][record.get_short_form]["prescription"] + record.value_numeric)
      elsif record.definition_id == dispensation_id
        @values[record.value_date][record.get_short_form]["dispensation"] = (@values[record.value_date][record.get_short_form]["dispensation"] + record.value_numeric)
      elsif record.definition_id == relocation_id
        @values[record.value_date][record.get_short_form]["relocation"] = (@values[record.value_date][record.get_short_form]["relocation"] + record.value_numeric)
      elsif record.definition_id == drug_given_to_id
        @values[record.value_date][record.get_short_form]["ppo_who_received_drugs"] = (@values[record.value_date][record.get_short_form]["ppo_who_received_drugs"] + record.value_numeric)
      end
    end


    render :layout => 'report_layout'
  end

  def aggregate_report
    @title = "Aggregate Report From #{params[:start_date].to_date.strftime("%d %b %Y")} To #{params[:end_date].to_date.strftime("%d %b %Y")}"
    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id
    relocation_id = Definition.where(:name => "relocation").first.id
    drug_given_to_id = Definition.where(:name => "People who received drugs").first.id
    defns = [prescription_id,dispensation_id, relocation_id, drug_given_to_id]
    @values = {}
    @pres_trend = {}
    @disp_trend = {}
    @rel_trend = {}

    obs = Observation.find_by_sql("SELECT value_date, definition_id, value_drug, SUM(value_numeric) AS value_numeric
                                  FROM observations where definition_id in (#{defns.join(',')}) and value_date >= '#{params[:start_date]}'
                                  AND value_date <= '#{params[:end_date]}' GROUP BY definition_id, value_date,value_drug
                                  ORDER BY value_date ASC")

    (obs || []).each do |record|

      @values[record.value_date] = {} unless !@values[record.value_date].blank?
      @values[record.value_date][record.get_short_form] = {"prescription" => 0, "dispensation" => 0, "relocation" => 0, "ppo_who_received_drugs" => 0} unless !@values[record.value_date][record.get_short_form].blank?
      if record.definition_id == prescription_id
        @values[record.value_date][record.get_short_form]["prescription"] = (@values[record.value_date][record.get_short_form]["prescription"] + record.value_numeric)
        @pres_trend[record.get_short_form].blank? ? @pres_trend[record.get_short_form] = [[record.value_date,record.value_numeric]] : @pres_trend[record.get_short_form] << [record.value_date,record.value_numeric]

      elsif record.definition_id == dispensation_id
        @values[record.value_date][record.get_short_form]["dispensation"] = (@values[record.value_date][record.get_short_form]["dispensation"] + record.value_numeric)
        @disp_trend[record.get_short_form].blank? ? @disp_trend[record.get_short_form] = [[record.value_date,record.value_numeric]] : @disp_trend[record.get_short_form] << [record.value_date,record.value_numeric]

      elsif record.definition_id == relocation_id
        @values[record.value_date][record.get_short_form]["relocation"] = (@values[record.value_date][record.get_short_form]["relocation"] + record.value_numeric)
        @rel_trend[record.get_short_form].blank? ? @rel_trend[record.get_short_form] = [[record.value_date,record.value_numeric]] : @rel_trend[record.get_short_form] << [record.value_date,record.value_numeric]

      elsif record.definition_id == drug_given_to_id
        @values[record.value_date][record.get_short_form]["ppo_who_received_drugs"] = (@values[record.value_date][record.get_short_form]["ppo_who_received_drugs"] + record.value_numeric)
      end
    end

    render :layout => 'report_layout'
  end

  def drug_report
    @title = "Drug Stock Report For #{params[:drug]}"
    defns = Definition.where(:name => ["Supervision verification", "People who received drugs",
                                       "Clinic verification","People prescribed drug"]).collect{|x| x.definition_id}

    @values = Hash.new()
    @values["All"] = {}

    obs = Observation.find(:all,:order => "value_date ASC",
                           :conditions => ["definition_id in (?) AND value_drug = ? AND value_date >= ? AND value_date <= ?",
                                           defns,params[:drug],params[:start_date],params[:end_date]])

    (obs || []).each do |record|
      @values[record.site.name] = {} unless !@values[record.site.name].blank?
      @values[record.site.name][record.value_date] = {"supervision_count" => 0,"clinic_count" => 0,
                                                      "ppo_who_received_drugs" => 0, "ppo_prescribed_drugs" => 0} unless !@values[record.site.name][record.value_date].blank?
      @values["All"][record.value_date] = {"supervision_count" => 0,"clinic_count" => 0,
                                           "ppo_who_received_drugs" => 0, "ppo_prescribed_drugs" => 0} unless !@values["All"][record.value_date].blank?

      case (record.definition_name.downcase)
        when "supervision verification" :
          @values[record.site.name][record.value_date]["supervision_count"] = record.value_numeric
          @values["All"][record.value_date]["supervision_count"] += record.value_numeric
        when "clinic verification":
          @values[record.site.name][record.value_date]["clinic_count"] = record.value_numeric
          @values["All"][record.value_date]["clinic_count"] += record.value_numeric
        when "people who received drugs":
          @values[record.site.name][record.value_date]["ppo_who_received_drugs"] = record.value_numeric
          @values["All"][record.value_date]["ppo_who_received_drugs"] += record.value_numeric
        when "people prescribed drug":
          @values[record.site.name][record.value_date]["ppo_prescribed_drugs"] = record.value_numeric
          @values["All"][record.value_date]["ppo_prescribed_drugs"] += record.value_numeric
      end

    end
    @days = obs.collect{|x| x.value_date}.uniq.sort.reverse

    @sites = @values.keys.sort!

    render :layout => 'report_layout'
  end

  def drug_utilization_report
    @title = "Drug Utilization Report For #{params[:drug]} "

    defns = Definition.where(:name => ["prescription","dispensation","relocation", "People who received drugs",
                                       "People prescribed drug"]).collect{|x| x.definition_id}

    @values = Hash.new()
    @values["All"] = {}

    obs = Observation.find(:all,:order => "value_date ASC",
      :conditions => ["definition_id in (?) AND value_drug = ? AND value_date >= ? AND value_date <= ?",
        defns,params[:drug],params[:start_date],params[:end_date]])

    (obs || []).each do |record|
      @values[record.site.name] = {} unless !@values[record.site.name].blank?
      @values[record.site.name][record.value_date] = {"prescription" => 0, "dispensation" => 0, "relocation" => 0,
        "ppo_who_received_drugs" => 0, "ppo_prescribed_drugs" => 0} unless !@values[record.site.name][record.value_date].blank?
      @values["All"][record.value_date] = {"prescription" => 0, "dispensation" => 0, "relocation" => 0,
        "ppo_who_received_drugs" => 0, "ppo_prescribed_drugs" => 0} unless !@values["All"][record.value_date].blank?

      case (record.definition_name.downcase)
      when "prescription" :
          @values[record.site.name][record.value_date]["prescription"] = record.value_numeric
        @values["All"][record.value_date]["prescription"] += record.value_numeric
      when "dispensation":
          @values[record.site.name][record.value_date]["dispensation"] = record.value_numeric
        @values["All"][record.value_date]["dispensation"] += record.value_numeric
      when "relocation":
          @values[record.site.name][record.value_date]["relocation"] =  record.value_numeric
        @values["All"][record.value_date]["relocation"] += record.value_numeric
      when "people who received drugs":
          @values[record.site.name][record.value_date]["ppo_who_received_drugs"] = record.value_numeric
        @values["All"][record.value_date]["ppo_who_received_drugs"] += record.value_numeric
      when "people prescribed drug":
          @values[record.site.name][record.value_date]["ppo_prescribed_drugs"] = record.value_numeric
        @values["All"][record.value_date]["ppo_prescribed_drugs"] += record.value_numeric
      end

    end
    @days = obs.collect{|x| x.value_date}.uniq.sort.reverse

    @sites = @values.keys.sort!

    render :layout => 'report_layout'
  end


  def stock_out_estimates
    @stocks = {}
    
    unless params[:name] && ["stock_movement", "months_of_stock"].include?(params[:name])
      @stocks = Observation.drug_stock_out_predictions(params[:type])
    end

    @sites = Site.all.map(&:name)
    @drugs = []
    if params[:name] == "stock_movement"
      definition_id = Definition.where(:name => "Supervision verification").first.id
      site_id = Site.find_by_name(params[:site_name]).id
      @drugs = Observation.find(:all,
        :select => ["value_drug"],
        :order => ["value_date"],
        :conditions => ["site_id = ? AND definition_id = ? AND value_date < ?",
          site_id, definition_id, params[:end_date].to_date]).map(&:value_drug).uniq
    end

    @drug_map = drug_map
    @updates = Observation.site_update_dates
    render :layout => 'report_layout'
  end

  def months_of_stock
    
    @site = params[:site_name]
    @stocks = Observation.drug_stock_out_predictions(params[:type])
    
    @stocks_for_high_charts = filter(@stocks)
        
    @site_names = @stocks_for_high_charts.keys
    @updates = Observation.site_update_dates
    render :partial => "months_of_stock" and return
  end

  def filter(stocks)
    result = {}
    sites = stocks.keys
    
    drugs = []
    sites.each do |site|

      arr = []
      result[site] = stocks[site].keys.each do|drug|
       
        expected = (stocks[site][drug]["stock_level"].to_i/60.0)  rescue 0
       
        consumption_rate = ((stocks[site][drug]["rate"].to_i * 0.5) rescue 0) # x pills/days == 0.5 tins of 60  per month
        months_of_stock = (consumption_rate == 0 && expected > 0) ? 9 : (expected/consumption_rate)  rescue 0
        months_of_stock = (months_of_stock.blank? ? 0 :  months_of_stock).to_f.round(2)

        drugs << drug
        arr << ["#{drug}", months_of_stock, expected.round, consumption_rate]
      end
      site_id = Site.find_by_name(site).id
      Observation.find_by_sql("SELECT DISTINCT value_drug FROM observations WHERE value_numeric != 0 AND site_id = #{site_id}").map(&:value_drug).each do |drg|
        next if  drg.blank? || drugs.include?(drg)
        arr << ["#{drg}", 0, 0, 0]
      end
      result[site] = (arr || []).sort {|a,b| a[1] <=> b[1]}.reverse
    end
    
    return result
  end

  def stock_movement

    start_date = params[:start_date].to_date
    end_date = params[:end_date].to_date

    definition_id = Definition.where(:name => "Supervision verification").first.id
    site_id = Site.find_by_name(params[:site_name]).id
    
    stocks = {}
   
    controlled_bound = (Observation.find(:last, :order => ["value_date ASC"],
        :select => ["value_date"],
        :conditions => ["value_drug = ? AND site_id = ? AND definition_id = ? AND DATE(value_date) < ?",
          params[:drug_name], site_id, definition_id, start_date]).value_date.to_date rescue nil) || start_date
   
    data = Observation.find(:all,
      :select => ["value_drug, value_numeric, value_date"],
      :order => ["value_date"],
      :conditions => ["value_drug = ? AND site_id = ? AND definition_id = ? AND value_date BETWEEN ? AND ?",
        params[:drug_name], site_id, definition_id, controlled_bound, end_date])
    
    @drugs = data.map(&:value_drug).uniq
    data.each do |data|
    
      stocks[data.value_drug] = {} unless stocks.keys.include?(data.value_drug)
      value = data.value_numeric/60 rescue 0
      
      stocks[data.value_drug][data.value_date.to_date] = value
    end

    n = controlled_bound
    @stocks = {}
    stocks.each do |drug, data|

      @stocks[drug] = [] unless @stocks.keys.include?(drug)

      latestcount = 0
      while n <= params[:end_date].to_date
      
        if !data[n.to_date].blank? && data[n.to_date].to_i > 0
          latestcount = data[n.to_date]
        else
          latestcount = latestcount - Observation.dispensed(drug, (n.to_date - 1.days))
        end
        @stocks[drug] << [n, latestcount] unless n.to_date < start_date.to_date
        n = n + 1.day
      end
      n = controlled_bound
    end
   
    @stocks.each{|k, arr|
      @stocks[k] = arr.sort{|a,b|a[0].to_date <=> b[0].to_date}
    }

    puts "#{params[:drug_name]}"
    
    render :partial => "stock_movement" and return
  end
  
  def drugs

    drug_list = Observation.find_by_sql("SELECT DISTINCT value_drug FROM observations ").collect{|x| x.value_drug}

    return drug_list
  end

  def drug_map
    
    drug_list = Observation.find_by_sql("SELECT DISTINCT value_drug FROM observations ").collect{|x| [x.value_drug, x.get_short_form]}.uniq

    return drug_list
  end

  def delivery_report
    @site = "?"
    site_id = -1
    if params[:delivery_code].blank?
      site = Site.find_by_name(params[:site_name])
      return {} if site.blank?
      site_id = site.id
    else
      
      site_id = Observation.site_by_code(params[:delivery_code])
    end
    
    if site_id.blank? || site_id < 1
      @stocks = {}
    else
      @site = Site.find(site_id).name
      start_date = params[:start_date] || nil
      end_date = params[:end_date] || nil
      delivery_code = params[:delivery_code] || nil    
      @stocks = Observation.deliveries(site_id, start_date, end_date, delivery_code)
    end
    
    render :layout => 'report_layout'
  end

  def create_notification(site_id, date, notice, drug)

    notice_defn = Definition.find_by_name("Notice")
    state_defn = Definition.find_by_name("New")

    obs = Observation.where(:site_id => site_id,
                            :definition_id => notice_defn.id,
                            :value_drug => drug,
                            :value_date => date,
                            :value_text => notice
    ).first

    if obs.blank?
      obs = Observation.create(:site_id => site_id,
                               :definition_id => notice_defn.id,
                               :value_drug => drug,
                               :value_date => date,
                               :value_text => notice
      )
      state = State.create(:observation_id => obs.id, :state => state_defn.name)
    end
  end

  def self.find_significant_disp_pres_diff(start_date ,end_date)

    #This function gets significant differences between prescriptions and dispensations
    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id

    issues = Hash.new([])
    prescriptions = Observation.where("definition_id = ? AND value_date >= ? AND value_date <= ?", prescription_id ,start_date, end_date)

    (prescriptions || []).each do |prescription|
      #getting dispensation on given day for specific drug
      dispensation = Observation.where("definition_id = ? AND value_date = ? AND value_drug = ? AND site_id = ?",
                                       dispensation_id, prescription.value_date,prescription.value_drug, prescription.site_id)

      issues[prescription.site.name] = [] if issues[prescription.site.name].blank?
      #Checking existence of dispensation and percentage of difference

      if dispensation.blank?
        issues[prescription.site.name] << "#{prescription.get_short_form} has prescriptions but no dispensations on #{prescription.value_date.strftime('%d %B %Y')}"
      else
        percent = (((prescription.value_numeric.to_f - dispensation[0].value_numeric.to_f)/prescription.value_numeric.to_f)*100).round(2)
        if percent >= prescription.site.threshold
          notice = "#{percent.abs}% more prescriptions than dispensations for #{prescription.get_short_form} on #{prescription.value_date.strftime('%d %B %Y')}"
          create_notification(prescription.site_id,prescription.value_date, notice, prescription.get_short_form)
          issues[prescription.site.name] << "#{percent.abs}% more prescriptions than dispensations for #{prescription.get_short_form} on #{prescription.value_date.strftime('%d %B %Y')}"
        elsif percent <= -prescription.site.threshold
          notice = "#{percent.abs}% more dispensations than prescriptions for #{prescription.get_short_form} on #{prescription.value_date.strftime('%d %B %Y')}"
         create_notification(prescription.site_id,prescription.value_date, notice, prescription.get_short_form)
        end
      end
    end

    dispensations = Observation.where("definition_id = ? AND value_date >= ? AND value_date <= ?", dispensation_id,start_date,end_date)

    (dispensations || []).each do |dispensation|
      #Getting prescription for specific drug on given date
      prescription = Observation.find(:first, :conditions => ["definition_id = ? AND value_date = ? AND value_drug = ? AND site_id = ?",
                                                              prescription_id, dispensation.value_date,dispensation.value_drug, dispensation.site_id])
      if prescription.blank?
        issues[dispensation.site.name] = [] if issues[dispensation.site.name].blank?
        noitice = "#{dispensation.get_short_form} has dispensation but no prescriptions on #{dispensation.value_date.strftime('%d %B %Y')}"
        create_notification(dispensation.site_id,dispensation.value_date, notice, dispensation.get_short_form)
        issues[dispensation.site.name] << "#{dispensation.get_short_form} has dispensation but no prescriptions on #{dispensation.value_date.strftime('%d %B %Y')}"
      end
    end

    issues
  end

end
