class HomeController < ApplicationController
  def index
    @lastdate = Observation.find_by_sql("SELECT site_id, max(value_date) as max_date FROM observations
                                        group by site_id order by max_date asc ;").first.max_date rescue nil
    @notices = ReportTool.find_significant_disp_pres_diff((Date.today - 7.days), Date.today)
    @notices += ReportTool.find_dispensation_without_prescriptions((Date.today - 7.days), Date.today)
    graph()
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
        pres_trend[record.value_drug].blank? ? pres_trend[record.value_drug] = [[record.value_date,record.value_numeric]] : pres_trend[record.value_drug] << [record.value_date,record.value_numeric]

      elsif record.definition_id == dispensation_id
        disp_trend[record.value_drug].blank? ? disp_trend[record.value_drug] = [[record.value_date,record.value_numeric]] : disp_trend[record.value_drug] << [record.value_date,record.value_numeric]

      elsif record.definition_id == relocation_id
        rel_trend[record.value_drug].blank? ? rel_trend[record.value_drug] = [[record.value_date,record.value_numeric]] : rel_trend[record.value_drug] << [record.value_date,record.value_numeric]
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
        pres_trend[record.value_drug].blank? ? pres_trend[record.value_drug] = [[record.value_date,record.value_numeric]] : pres_trend[record.value_drug] << [record.value_date,record.value_numeric]

      elsif record.definition_id == dispensation_id
        disp_trend[record.value_drug].blank? ? disp_trend[record.value_drug] = [[record.value_date,record.value_numeric]] : disp_trend[record.value_drug] << [record.value_date,record.value_numeric]

      elsif record.definition_id == relocation_id
        rel_trend[record.value_drug].blank? ? rel_trend[record.value_drug] = [[record.value_date,record.value_numeric]] : rel_trend[record.value_drug] << [record.value_date,record.value_numeric]
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

end


