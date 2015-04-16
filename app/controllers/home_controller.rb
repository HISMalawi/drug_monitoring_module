class HomeController < ApplicationController
  def index
    @sites = Site.all
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
    (Site.all || []).each do |source|
      notices = ReportTool.get_notices_summary(source.id)
      site = {
          'region' => source["region"],
          'x' => source["x"],
          'y' =>source["y"],
          'name' => source["name"],
          'proportion' => 0,
          'new_notices' => notices["New"],
          "not_investigating" => notices["Investigating"]
       }

      @sites << site
    end
    render :layout => false
  end
end


