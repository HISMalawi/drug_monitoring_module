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
    site = Site.find_by_name(params[:site])
    defns = [prescription_id,dispensation_id]
    @values = {}
    obs = Observation.find(:all,:order => "value_date DESC",
      :conditions => ["definition_id in (?) AND site_id = ? AND value_date >= ? AND value_date <= ?",
        defns,site.id,params[:start_date],params[:end_date]])
    (obs || []).each do |record|

      @values[record.value_date] = {} unless !@values[record.value_date].blank?
      @values[record.value_date][record.value_drug] = {"prescription" => 0, "dispensation" => 0} unless !@values[record.value_date][record.value_drug].blank?
      if record.definition_id == prescription_id
        @values[record.value_date][record.value_drug]["prescription"] = (@values[record.value_date][record.value_drug]["prescription"] + record.value_numeric)
      else
        @values[record.value_date][record.value_drug]["dispensation"] = (@values[record.value_date][record.value_drug]["dispensation"] + record.value_numeric)
      end
    end


    render :layout => 'report_layout'
  end

  def aggregate_report
    @title = "Aggregate Report From #{params[:start_date].to_date.strftime("%d %b %Y")} To #{params[:end_date].to_date.strftime("%d %b %Y")}"
    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id
    defns = [prescription_id,dispensation_id]
    @values = {}
    @pres_trend = {}
    @disp_trend = {}
    @pres_days = []
    @disp_days = []
    obs = Observation.find_by_sql("SELECT value_date, definition_id, value_drug, SUM(value_numeric) AS value_numeric
                                  FROM observations where definition_id in (#{defns.join(',')}) and value_date >= '#{params[:start_date]}'
                                  AND value_date <= '#{params[:end_date]}' GROUP BY definition_id, value_date,value_drug
                                  ORDER BY value_date ASC")

    (obs || []).each do |record|

      @values[record.value_date] = {} unless !@values[record.value_date].blank?
      @values[record.value_date][record.value_drug] = {"prescription" => 0, "dispensation" => 0} unless !@values[record.value_date][record.value_drug].blank?
      if record.definition_id == prescription_id
        @values[record.value_date][record.value_drug]["prescription"] = (@values[record.value_date][record.value_drug]["prescription"] + record.value_numeric)
        @pres_trend[record.value_drug].blank? ? @pres_trend[record.value_drug] = [[record.value_date,record.value_numeric]] : @pres_trend[record.value_drug] << [record.value_date,record.value_numeric]
        @pres_days << record.value_date.to_time.utc.to_i
      else
        @values[record.value_date][record.value_drug]["dispensation"] = (@values[record.value_date][record.value_drug]["dispensation"] + record.value_numeric)
        @disp_trend[record.value_drug].blank? ? @disp_trend[record.value_drug] = [[record.value_date,record.value_numeric]] : @disp_trend[record.value_drug] << [record.value_date,record.value_numeric]
        @disp_days << record.value_date
      end
    end

    render :layout => 'report_layout'
  end

  def drug_report
    @title = "Drug Report For #{params[:drug]} From #{params[:start_date].to_date.strftime("%d %b %Y")} To #{params[:end_date].to_date.strftime("%d %b %Y")}"
    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id
    defns = [prescription_id,dispensation_id]
    @values = {}
    @prescription = 0
    @dispensation = 0
    @days = []
    obs = Observation.find(:all,:order => "value_date ASC",
      :conditions => ["definition_id in (?) AND value_drug = ? AND value_date >= ? AND value_date <= ?",defns,params[:drug],params[:start_date],params[:end_date]])
    (obs || []).each do |record|
      @values[record.value_date] = {"prescription" => 0, "dispensation" => 0} unless !@values[record.value_date].blank?
      @days << record.value_date
      if record.definition_id == prescription_id
        @values[record.value_date]["prescription"] = (@values[record.value_date]["prescription"] + record.value_numeric)
        @prescription += record.value_numeric
      else
        @values[record.value_date]["dispensation"] = (@values[record.value_date]["dispensation"] + record.value_numeric)
        @dispensation += record.value_numeric
      end
    end
    @days = @days.uniq!
    render :layout => 'report_layout'
  end

  def stock_out_estimates
 
    @stocks = Observation.drug_stock_out_predictions(params[:type])
    @updates = Observation.site_update_dates
    render :layout => 'report_layout'
  end

  def drugs

    defns = Definition.where(:name=> ["prescription","dispensation"]).collect{|x| x.definition_id}

    drug_list = Observation.find_by_sql("SELECT DISTINCT value_drug FROM observations "+
        " WHERE definition_id in (#{defns.join(',')})").collect{|x| x.value_drug}

    return drug_list
  end
end
