class ReportController < ApplicationController

  def index
  end

  def site_list
    @sites = Site.all
  end

  def report_menu
    @sites = Site.all_sites
    @drugs = drugs
  end

  def process_report

    start_date = params[:start_date]
    end_date = params[:end_date]

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
    @title = "Site Report For #{params[:site]}  From #{params[:start_date]} To #{params[:end_date]}"
    render :layout => 'report_layout'
  end

  def aggregate_report
    @title = "Aggregate Report From #{params[:start_date]} To #{params[:end_date]}"
    render :layout => 'report_layout'
  end

  def drug_report
    @title = "Drug Report For #{params[:drug]} From #{params[:start_date]} To #{params[:end_date]}"
    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id
    defns = [prescription_id,dispensation_id]
    @values = {}
    @prescription = 0
    @dispensation = 0
    obs = Observation.find(:all,:order => "value_date DESC",
                           :conditions => ["definition_id in (?) AND value_drug = ? AND value_date >= ? AND value_date <= ?",defns,params[:drug],params[:start_date],params[:end_date]])
    (obs || []).each do |record|
      @values[record.value_date] = {"prescription" => 0, "dispensation" => 0} unless !@values[record.value_date].blank?
       if record.definition_id == prescription_id
         @values[record.value_date]["prescription"] = (@values[record.value_date]["prescription"] + record.value_numeric)
         @prescription += record.value_numeric
       else
         @values[record.value_date]["dispensation"] = (@values[record.value_date]["dispensation"] + record.value_numeric)
         @dispensation += record.value_numeric
       end
    end

    render :layout => 'report_layout'
  end

  def drugs

    defns = Definition.where(:name=> ["prescription","dispensation"]).collect{|x| x.definition_id}

    drug_list = Observation.find_by_sql("SELECT DISTINCT value_drug FROM observations "+
                          " WHERE definition_id in (#{defns.join(',')})").collect{|x| x.value_drug}

    return drug_list
  end

end
