class ReportController < ApplicationController

  def index

  end

  def menu
    @tree = {}
    @tree["Drug categories"] = {}
    hiv_unit_drugs = Definition.find_by_name("HIV Unit Drugs").id
    @tree["Drug categories"]["ARV"] = []
    @tree["Drug categories"]['Opportunistic Infection  medicine'] = []
    @tree["Drug categories"]['Antibiotics'] = []
    @tree["Drug categories"]['Analgesic'] = []
    @tree["Drug categories"]['Antiviral'] = []
    @tree["Drug categories"]['Antifungal'] = []
    @tree["Drug categories"]['Antimalarial'] = []
    @tree["Drug categories"]['Unknown'] = []

    DrugSet.where(:definition_id =>hiv_unit_drugs ).order("weight asc").each do |drug_set|
      drug_cms = drug_set.drug_cms
      @tree["Drug categories"][drug_cms.get_category] << "#{drug_cms.short_name} #{drug_cms.strength} #{drug_cms.tabs}"
    end
    #@sheets["Sheets"] = {}

  end

  def site_list
    @sites = Site.where(:active => true)
  end

  def report_menu
    @sites = Site.where(:active => true).collect { |x| x.name }
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
        site = params[:sitename]
        redirect_to :action => 'site_report', :site => site, :start_date => start_date, :end_date => end_date
      when "stock movement"
        redirect_to :action => 'stock_out_estimates', :start_date => start_date, :end_date => end_date,
          :type => "verified_by_supervision", :name => "stock_movement", :site_name => params[:sitename]
      when "delivery report"
        redirect_to :action => 'delivery_report', :start_date => start_date, :end_date => end_date,
          :name => "delivery_report", :site_name => params[:sitename], :delivery_code => params[:delivery_code]
    end
  end

  def site_report
    @title = "Site Report For #{params[:site]} From #{params["start_date"].to_date.strftime("%d %B %Y")} To #{params["end_date"].to_date.strftime("%d %B %Y")}"

    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id
    relocation_id = Definition.where(:name => "relocation").first.id
    drug_given_to_id = Definition.where(:name => "People who received drugs").first.id
    defns = [prescription_id,dispensation_id, relocation_id, drug_given_to_id]
    site = Site.find_by_name(params[:site])

    @values = {}
    obs = Observation.where("definition_id in (?) AND site_id = ? AND value_date >= ? AND value_date <= ?",
                             [defns,site.id,params[:start_date],params[:end_date]]).order("value_date DESC")

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


    #render :layout => 'report_layout'
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

    #render :layout => 'report_layout'
  end

  def drug_report
    @title = "Drug Stock Report For #{params[:drug]} From #{params["start_date"].to_date.strftime("%d %B %Y")} To #{params["end_date"].to_date.strftime("%d %B %Y")}"
    defns = Definition.where(:name => ["Supervision verification", "People who received drugs",
                                       "Clinic verification","People prescribed drug"]).collect{|x| x.definition_id}

    @values = Hash.new()
    @values["All"] = {}

    obs = Observation.where("definition_id in (?) AND value_drug = ? AND value_date >= ? AND value_date <= ?",
                            [defns,params[:drug],params[:start_date],params[:end_date]]).order("value_date ASC")


    (obs || []).each do |record|
      @values[record.site.name] = {} unless !@values[record.site.name].blank?
      @values[record.site.name][record.value_date] = {"supervision_count" => 0,"clinic_count" => 0,
                                                      "ppo_who_received_drugs" => 0, "ppo_prescribed_drugs" => 0} unless !@values[record.site.name][record.value_date].blank?
      @values["All"][record.value_date] = {"supervision_count" => 0,"clinic_count" => 0,
                                           "ppo_who_received_drugs" => 0, "ppo_prescribed_drugs" => 0} unless !@values["All"][record.value_date].blank?

      case (record.definition_name.downcase)
        when "supervision verification"
          @values[record.site.name][record.value_date]["supervision_count"] = record.value_numeric
          @values["All"][record.value_date]["supervision_count"] += record.value_numeric
        when "clinic verification"
          @values[record.site.name][record.value_date]["clinic_count"] = record.value_numeric
          @values["All"][record.value_date]["clinic_count"] += record.value_numeric
        when "people who received drugs"
          @values[record.site.name][record.value_date]["ppo_who_received_drugs"] = record.value_numeric
          @values["All"][record.value_date]["ppo_who_received_drugs"] += record.value_numeric
        when "people prescribed drug"
          @values[record.site.name][record.value_date]["ppo_prescribed_drugs"] = record.value_numeric
      end
          @values["All"][record.value_date]["ppo_prescribed_drugs"] += record.value_numeric

    end
    @days = obs.collect{|x| x.value_date}.uniq.sort.reverse

    @sites = @values.keys.sort!

#    render :layout => 'report_layout'
  end

  def drug_utilization_report
    @title = "Drug Utilization Report For #{params[:drug]} From #{params["start_date"].to_date.strftime("%d %B %Y")} To
              #{params["end_date"].to_date.strftime("%d %B %Y")}"

    defns = Definition.where(:name => ["prescription","dispensation","relocation", "People who received drugs",
                                       "People prescribed drug"]).collect{|x| x.definition_id}

    @values = Hash.new()
    @values["All"] = {}

    obs = Observation.find("definition_id in (?) AND value_drug = ? AND value_date >= ? AND value_date <= ?",
                           [defns,params[:drug],params[:start_date],params[:end_date]]).order("value_date ASC")


    (obs || []).each do |record|
      @values[record.site.name] = {} unless !@values[record.site.name].blank?
      @values[record.site.name][record.value_date] = {"prescription" => 0, "dispensation" => 0, "relocation" => 0,
        "ppo_who_received_drugs" => 0, "ppo_prescribed_drugs" => 0} unless !@values[record.site.name][record.value_date].blank?
      @values["All"][record.value_date] = {"prescription" => 0, "dispensation" => 0, "relocation" => 0,
        "ppo_who_received_drugs" => 0, "ppo_prescribed_drugs" => 0} unless !@values["All"][record.value_date].blank?

      case (record.definition_name.downcase)
      when "prescription"
          @values[record.site.name][record.value_date]["prescription"] = record.value_numeric
        @values["All"][record.value_date]["prescription"] += record.value_numeric
      when "dispensation"
          @values[record.site.name][record.value_date]["dispensation"] = record.value_numeric
        @values["All"][record.value_date]["dispensation"] += record.value_numeric
      when "relocation"
          @values[record.site.name][record.value_date]["relocation"] =  record.value_numeric
        @values["All"][record.value_date]["relocation"] += record.value_numeric
      when "people who received drugs"
          @values[record.site.name][record.value_date]["ppo_who_received_drugs"] = record.value_numeric
        @values["All"][record.value_date]["ppo_who_received_drugs"] += record.value_numeric
      when "people prescribed drug"
          @values[record.site.name][record.value_date]["ppo_prescribed_drugs"] = record.value_numeric
        @values["All"][record.value_date]["ppo_prescribed_drugs"] += record.value_numeric
      end

    end
    @days = obs.collect{|x| x.value_date}.uniq.sort.reverse

    @sites = @values.keys.sort!

 #   render :layout => 'report_layout'
  end


  def stock_out_estimates
    @stocks = {}
    
    unless params[:name] && ["stock_movement", "months_of_stock"].include?(params[:name])
      @stocks = Observation.drug_stock_out_predictions(params[:type])
    end

    @sites = Site.where(:active => true).map(&:name)
    @drugs = []
    if params[:name] == "stock_movement"
      definition_id = Definition.where(:name => "Supervision verification").first.id
      site_id = Site.find_by_name(params[:site_name]).id
      @drugs = Observation.where("site_id = ? AND definition_id = ? AND value_date < ?",
                                 [site_id, definition_id, params[:end_date].to_date]).order("value_date").map(&:value_drug).uniq
    end

    @drug_map = drug_map
    @updates = Observation.site_update_dates

  end

  def months_of_stock

    @site = Site.find_by_name(params[:site_name])
    @list = {}
    @unitQty = (params[:qty] || preferred_units.scan(/\d+/)[0]).to_i rescue 60
    @unitQty =  60 if @unitQty == 0
    @unitQty = @unitQty.to_f

    unless @site.blank?

      hiv_unit_drugs = DrugSet.where(:definition_id => Definition.find_by_name("HIV Unit Drugs").id).order("weight asc")

      #raise hiv_unit_drugs.collect{|x| x.drug.short_name}.inspect
      (hiv_unit_drugs || []).each do |drug|

        stock_level = Observation.calculate_stock_level(drug.drug_id,@site.id)
        stock_level = (stock_level / @unitQty).round # stock level comes in pills/day here we convert it to tins/month
        disp_rate = Observation.drug_dispensation_rates(drug.drug_id,@site.id)
        disp_rate = ((disp_rate.to_f * 0.5) * 60.0/@unitQty).round #rate is an avg of pills dispensed per day. here we convert it to tins per month
        month_of_stock = Observation.calculate_month_of_stock(drug.drug_id, @site.id).to_f
        stocked_out = (disp_rate.to_i != 0 && month_of_stock.to_f.round(3) == 0.00)

        active = (disp_rate.to_i == 0 && stock_level.to_i != 0)? false : true
        drug_cms = DrugCms.find(drug.drug_id)
        @list["#{drug_cms.short_name} #{drug_cms.strength} #{drug_cms.tabs}"] = {"month_of_stock" => month_of_stock,"weight" => drug.weight,
                                                     "stock_level" => stock_level, "consumption_rate" => disp_rate,
                                                     "stocked_out" => stocked_out, "active" => active
                                                    }
      end
    end

    @list = @list.sort_by{|drug, values| values["weight"]}

    render :layout => false
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

    @unitQty = (params[:qty] || preferred_units.scan(/\d+/)[0]).to_i rescue 60
    @unitQty =  60 if @unitQty == 0
    @unitQty = @unitQty.to_f

    start_date = params[:start_date].to_date
    end_date = params[:end_date].to_date

    definition_id = Definition.where(:name => "Supervision verification").first.id
    site_id = params[:site_id]
    drug = nil
    map = {}
    DrugCms.all.each do |drug_cms|
      short_name = "#{drug_cms.short_name} #{drug_cms.strength} #{drug_cms.tabs}"
      map[short_name] = drug_cms.drug_inventory_id
    end
    drug = map[params[:drug]]
    #drug = Drug.check(params[:drug])

    stocks = {}
   
    controlled_bound = (Observation.find(:last, :order => ["value_date ASC"],
        :select => ["value_date"],
        :conditions => ["value_drug = ? AND site_id = ? AND definition_id = ? AND DATE(value_date) < ?",
          drug, site_id, definition_id, start_date]).value_date.to_date rescue nil) || start_date

    data = Observation.where("value_drug = ? and site_id = ?  and definition_id = ? and value_date BETWEEN ? AND ?",
                             drug,site_id,definition_id, controlled_bound,end_date).select("value_drug, value_numeric, value_date").order("value_date")

    supervision_flags =  Observation.where("value_drug = ? and site_id = ?  and definition_id IN (?) and value_date BETWEEN ? AND ? AND value_numeric > 0",
                                        drug, site_id, Definition.where(:name => "Supervision Verification").first.id,
                                        controlled_bound,end_date).select("value_date").order("value_date"
    ).map(&:value_date)

    delivery_flags =  Observation.where("value_drug = ? and site_id = ?  and definition_id IN (?) and value_date BETWEEN ? AND ? AND value_numeric > 0",
                                        drug, site_id, Definition.where(:name => "New delivery").first.id,
                                        controlled_bound,end_date).select("value_date").order("value_date"
    ).map(&:value_date)

    relocation_flags = Observation.where("value_drug = ? and site_id = ?  and definition_id IN (?) and value_date BETWEEN ? AND ? AND value_numeric > 0",
                                       drug, site_id, Definition.where(:name => "Relocation").first.id,
                                       controlled_bound,end_date).select("value_date").order("value_date"
    ).map(&:value_date)

    @drugs = data.map(&:value_drug).uniq
    data.each do |data|
    
      stocks[data.value_drug] = {} unless stocks.keys.include?(data.value_drug)
      value = (data.value_numeric/@unitQty).round rescue 0
      
      stocks[data.value_drug][data.value_date.to_date] = value
    end

    @stocks = {}
    n = controlled_bound

    while n <= params[:end_date].to_date
      stock_level = (Observation.calculate_stock_level(drug, site_id, n)/@unitQty).round rescue 0
      @stocks[n.to_date]= {"stock_count" => stock_level}
      n = n + 1.day
    end
   # @stocks["relocation_dates"] = relocation_flags
    #@stocks["delivery_dates"] = delivery_flags
    #@stocks["supervision_dates"] = supervision_flags
    render :text => @stocks.to_json
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

    @unitQty = (params[:unitQty] || preferred_units.scan(/\d+/)[0]).to_i rescue 60
    @unitQty =  60 if @unitQty == 0
    @unitQty = @unitQty.to_f

    if request.get?
      @tree = {}
      @tree["Available Sites"] = Site.where(:active => true).collect{|x| x.name}
      @nojquery = true
    else
      @site = Site.find_by_name(params[:site_name])
      site_id = @site.id
      if params[:type].blank?
        start_date = params[:start_date] || nil
        @stocks = Observation.day_deliveries(site_id, start_date, @unitQty)
        result = view_context.day_deliveries(@stocks, nil)
      elsif params[:type] == "duration"
        @stocks = Observation.deliveries_in_range(site_id, params[:start_date],params[:end_date], @unitQty)
        result = view_context.day_deliveries(@stocks, params[:type])
      elsif params[:type] == "delivery_code"
        @stocks = Observation.deliveries_by_code(site_id, params[:d_code], @unitQty)
        result = view_context.code_deliveries(@stocks, params[:site_name])
      end

      render :text => result
    end


=begin
    #code from dmp 1.0 that is now redundant
    if params[:delivery_code].blank?
      site_id = Site.find_by_name(params[:site_name]).id
    else
      site_id = Observation.site_by_code(params[:delivery_code])
    end
    
    if site_id.blank? || site_id < 1
      @stocks = {}
    else
      start_date = params[:start_date] || nil
      end_date = params[:end_date] || nil
      delivery_code = params[:delivery_code] || nil
      @stocks = Observation.
      @site = Site.find(site_id).namedeliveries(site_id, start_date, end_date, delivery_code)
    end

    raise @stocks.inspect
=end
  end

  def months_of_stock_main
    @site = Site.find_by_name(params[:site])
    @list = {}

    unless @site.blank?


      hiv_unit_drugs = DrugSet.where(:definition_id => Definition.find_by_name("HIV Unit Drugs").id).order("weight asc")

      #raise hiv_unit_drugs.collect{|x| x.drug.short_name}.inspect
      (hiv_unit_drugs || []).each do |drug|

        stock_level = Observation.calculate_stock_level(drug.drug_id,@site.id)
        stock_level = stock_level / 60 # stock level comes in pills/day here we convert it to tins/month
        disp_rate = Observation.drug_dispensation_rates(drug.drug_id,@site.id)
        disp_rate = (disp_rate.to_f * 0.5).round #rate is an avg of pills dispensed per day. here we convert it to tins per month
        month_of_stock = Observation.calculate_month_of_stock(drug.drug_id, @site.id).to_f

        stocked_out = (disp_rate.to_i != 0 && month_of_stock.to_f.round(3) == 0.00)

        active = (disp_rate.to_i == 0 && stock_level.to_i != 0)? false : true
        drug = DrugCms.find(drug.drug_id)
        @list["#{drug.short_name} #{drug.strength} #{drug.tabs}"] = {"month_of_stock" => month_of_stock,"weight" => drug.weight,
                                                     "stock_level" => stock_level, "consumption_rate" => disp_rate,
                                                     "stocked_out" => stocked_out, "active" => active
                                                    }

      end
    end

    @list = @list.sort_by{|drug, values| values["weight"]}


=begin
#This chunk of code was edited out cause it was a primitive way to get the values needed though it works fine

    drugs = ['ABC/3TC (Abacavir and Lamivudine 60/30mg tablet)',
             'AZT/3TC (Zidovudine and Lamivudine 60/30 tablet)',
             'AZT/3TC (Zidovudine and Lamivudine 300/150mg)',
             'AZT/3TC/NVP (60/30/50mg tablet)',
             'AZT/3TC/NVP (300/150/200mg tablet)',
             'd4T/3TC (Stavudine Lamivudine 6/30mg tablet)',
             'd4T/3TC (Stavudine Lamivudine 30/150 tablet)',
             'Triomune baby (d4T/3TC/NVP 6/30/50mg tablet)',
             'd4T/3TC/NVP (30/150/200mg tablet)',
             'EFV (Efavirenz 200mg tablet)',
             'EFV (Efavirenz 600mg tablet)',
             'LPV/r (Lopinavir and Ritonavir 100/25mg tablet)',
             'LPV/r (Lopinavir and Ritonavir 200/50mg tablet)',
             'LPV/r (Lopinavir and Ritonavir syrup)',
             'ATV/r (Atazanavir 300mg/Ritonavir 100mg)',
             'NVP (Nevirapine 200 mg tablet)',
             'TDF/3TC (Tenofavir and Lamivudine 300/300mg tablet','TDF/3TC/EFV (300/300/600mg tablet)',
             'Cotrimoxazole (480mg tablet)',
             'Cotrimoxazole (960mg)', 'INH or H (Isoniazid 100mg tablet)', 'INH or H (Isoniazid 300mg tablet)']


    (drugs || []).each do |drug|

      month_of_stock = Observation.calculate_month_of_stock(drug, @site.id)

      unless (month_of_stock.is_a? String ||  month_of_stock.nan?)
        stock_level = Observation.calculate_stock_level(drug,@site.id)
        disp_rate = Observation.drug_dispensation_rates(drug,@site.id)

        @list[drug] = {"month_of_stock" => month_of_stock,
                                                "stock_level" => stock_level, "consumption_rate" => (disp_rate.to_i rescue 0) }

      end

=end


    render :layout => false
  end

  def physical_stock_summary

    @unitQty = (params[:qty] || preferred_units.scan(/\d+/)[0]).to_i rescue 60
    @unitQty =  60 if @unitQty == 0
    @unitQty = @unitQty.to_f

    if request.get?
      @tree = {}
      @tree["Drug categories"] = {}
      hiv_unit_drugs = Definition.find_by_name("HIV Unit Drugs").id
      @tree["Drug categories"]["ARVs"] = DrugSet.where(:definition_id =>hiv_unit_drugs ).order("weight asc").collect{|x| x.get_short_name}
      @tree["Drug categories"]['Opportunistic Infection  medicine'] = {}
      @tree["Drug categories"]['Antibiotics'] = {}
      @tree["Drug categories"]['Analgesic'] = {}
      @tree["Drug categories"]['Antiviral'] = {}
      @tree["Drug categories"]['Antifungal'] = {}
      @tree["Drug categories"]['Antimalarial'] = {}
      @nojquery = true
    else

    end

  end

  def notices
    if request.get?
      @tree = {}
      @tree["Available Sites"] = Site.where(:active => true).collect{|x| x.name}
      @nojquery = true
    else

      @site = Site.find_by_name(params[:site_name])
      site_id = @site.id

      state = Definition.where(:name => params[:state]).first.id
      notice_defn = Definition.find_by_name("Notice").id

      notices = State.joins("INNER JOIN observations on states.observation_id = observations.observation_id
                                AND observations.site_id = #{site_id} AND states.state = #{state}
                                AND observations.definition_id = #{notice_defn}")

      render :text => view_context.notices_format(notices,params[:state])
    end

  end

  def get_comment

  end

  def update_notice

    state = State.where("state_id = ?", params[:row]).first

    unless state.blank?
      state.state = Definition.find_by_name(params[:state]).id
      state.save

      Observation.create({:definition_id => Definition.find_by_name("comment").id,
                          :value_text => params[:comment],
                          :creator => User.find_by_username(params[:editor]).id,
                          :value_numeric => state.id,
                          :value_date => Date.today,
                          :site_id => state.observation.site_id
                         })
    end
    render :text => true and return
  end

  def update_display_units
    preferred_units(params[:units])
    render :text => "ok"
  end

end
