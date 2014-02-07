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
    render :layout => 'report_layout'
  end

  def drugs

    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id

    drug_list = Observation.find_by_sql("SELECT DISTINCT value_drug FROM observations "+
                          " WHERE definition_id in (#{prescription_id}, #{dispensation_id})").collect{|x| x.value_drug}

    return drug_list
  end

end
