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

    start_date = params[:start_date].to_date.strftime("%Y-%m-%d")
    end_date = params[:end_date].to_date.strftime("%Y-%m-%d")

    case params[:report_type]
    when "drug report"
      drug = params[:drug]
      redirect_to :action => 'drug_report',:drug => drug, :start_date => start_date, :end_date => end_date
    when "aggregate report"
      redirect_to :action => 'aggregate_report', :start_date => start_date, :end_date => end_date
    when "site report"
      site = params[:site_name]
      redirect_to :action => 'site_report', :site => site, :start_date => start_date, :end_date => end_date
    end
  end

  def site_report
    @title = "Site Report For #{params[:site]}  From #{params[:start_date].to_date.strftime("%d %b %Y")} To #{params[:end_date].to_date.strftime("%d %b %Y")}"

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
      @values[record.value_date][record.value_drug] = {"prescription" => 0, "dispensation" => 0, "relocation" => 0, "ppo_who_received_drugs" => 0} unless !@values[record.value_date][record.value_drug].blank?
      if record.definition_id == prescription_id
        @values[record.value_date][record.value_drug]["prescription"] = (@values[record.value_date][record.value_drug]["prescription"] + record.value_numeric)
      elsif record.definition_id == dispensation_id
        @values[record.value_date][record.value_drug]["dispensation"] = (@values[record.value_date][record.value_drug]["dispensation"] + record.value_numeric)
      elsif record.definition_id == relocation_id
        @values[record.value_date][record.value_drug]["relocation"] = (@values[record.value_date][record.value_drug]["relocation"] + record.value_numeric)
      elsif record.definition_id == drug_given_to_id
        @values[record.value_date][record.value_drug]["ppo_who_received_drugs"] = (@values[record.value_date][record.value_drug]["ppo_who_received_drugs"] + record.value_numeric)
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
      @values[record.value_date][record.value_drug] = {"prescription" => 0, "dispensation" => 0, "relocation" => 0, "ppo_who_received_drugs" => 0} unless !@values[record.value_date][record.value_drug].blank?
      if record.definition_id == prescription_id
        @values[record.value_date][record.value_drug]["prescription"] = (@values[record.value_date][record.value_drug]["prescription"] + record.value_numeric)
        @pres_trend[record.value_drug].blank? ? @pres_trend[record.value_drug] = [[record.value_date,record.value_numeric]] : @pres_trend[record.value_drug] << [record.value_date,record.value_numeric]

      elsif record.definition_id == dispensation_id
        @values[record.value_date][record.value_drug]["dispensation"] = (@values[record.value_date][record.value_drug]["dispensation"] + record.value_numeric)
        @disp_trend[record.value_drug].blank? ? @disp_trend[record.value_drug] = [[record.value_date,record.value_numeric]] : @disp_trend[record.value_drug] << [record.value_date,record.value_numeric]

      elsif record.definition_id == relocation_id
        @values[record.value_date][record.value_drug]["relocation"] = (@values[record.value_date][record.value_drug]["relocation"] + record.value_numeric)
        @rel_trend[record.value_drug].blank? ? @rel_trend[record.value_drug] = [[record.value_date,record.value_numeric]] : @rel_trend[record.value_drug] << [record.value_date,record.value_numeric]

      elsif record.definition_id == drug_given_to_id
        @values[record.value_date][record.value_drug]["ppo_who_received_drugs"] = (@values[record.value_date][record.value_drug]["ppo_who_received_drugs"] + record.value_numeric)
      end
    end

    render :layout => 'report_layout'
  end

  def drug_report
    @title = "Drug Report For #{params[:drug]} From #{params[:start_date].to_date.strftime("%d %b %Y")} To #{params[:end_date].to_date.strftime("%d %b %Y")}"
    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id
    relocation_id = Definition.where(:name => "relocation").first.id
    drug_given_to_id = Definition.where(:name => "People who received drugs").first.id
    defns = [prescription_id,dispensation_id, relocation_id, drug_given_to_id]
    @values = {}
    @prescription = 0
    @dispensation = 0
    @relocation = 0

    obs = Observation.find(:all,:order => "value_date ASC",
      :conditions => ["definition_id in (?) AND value_drug = ? AND value_date >= ? AND value_date <= ?",defns,params[:drug],params[:start_date],params[:end_date]])
    (obs || []).each do |record|
      @values[record.value_date] = {"prescription" => 0, "dispensation" => 0, "relocation" => 0, "ppo_who_received_drugs" => 0} unless !@values[record.value_date].blank?
      if record.definition_id == prescription_id
        @values[record.value_date]["prescription"] = (@values[record.value_date]["prescription"] + record.value_numeric)
        @prescription += record.value_numeric
      elsif record.definition_id == dispensation_id
        @values[record.value_date]["dispensation"] = (@values[record.value_date]["dispensation"] + record.value_numeric)
        @dispensation += record.value_numeric
      elsif record.definition_id == relocation_id
        @values[record.value_date]["relocation"] = (@values[record.value_date]["relocation"] + record.value_numeric)
        @relocation += record.value_numeric
      else
        @values[record.value_date]["ppo_who_received_drugs"] = (@values[record.value_date]["ppo_who_received_drugs"] + record.value_numeric)
      end
    end
    @days = @values.keys.sort!

    render :layout => 'report_layout'
  end

  def stock_out_estimates
    @stocks = {}
    unless params[:name] && params[:name] == "months_of_stock" || params[:name] == "stock_movement"
      @stocks = Observation.drug_stock_out_predictions(params[:type])      
    end
    @sites = Site.all.map(&:name) 
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
       
        consumption_rate = ((stocks[site][drug]["rate"].to_i * 0.5) rescue 0)
        months_of_stock = (consumption_rate == 0 && expected > 0) ? 9 : (expected/consumption_rate)  rescue 0
        months_of_stock = months_of_stock.blank? ? 0 : (months_of_stock > 9 ? 9 : months_of_stock)

        drugs << drug
        arr << ["#{drug}", months_of_stock]
      end
      site_id = Site.find_by_name(site).id
      Observation.find_by_sql("SELECT DISTINCT value_drug FROM observations WHERE value_numeric != 0 AND site_id = #{site_id}").map(&:value_drug).each do |drg|
        next if  drg.blank? || drugs.include?(drg) #|| drg.match(/other|unknown/i)
        arr << ["#{drg}", 0]
      end
      result[site] = (arr || []).sort {|a,b| a[1] <=> b[1]}.reverse
    end
    
    return result
  end

  def stock_chart

    
  end
  
  def drugs


    drug_list = Observation.find_by_sql("SELECT DISTINCT value_drug FROM observations ").collect{|x| x.value_drug}

    return drug_list
  end
end
