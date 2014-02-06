class HomeController < ApplicationController
  def index
    if session[:user_id].blank?
      render :layout => 'unlogged'
    end
    graph()
  end

  def graph

    @days = []
    start = Date.today - 6.days
    (0..6).each do |i|
      @days << (start + i.days ).strftime('%A')
    end
    aggregates = aggregate(@days)
    drugs = drug()

    @disp_line_data_list = aggregates["dispensation_line"]
    @pres_line_data_list = aggregates["prescription_line"]

    @aggregate_pres_pie = []
    @aggregate_disp_pie = []

    (aggregates["prescription_pie"] || []).each do |drug, value|
      @aggregate_pres_pie << [drug,value]
    end
    (aggregates["dispensation_pie"] || []).each do |drug, value|
      @aggregate_disp_pie << [drug,value]
    end

    @drug_disp_line_data_list = drugs["dispensation_line"]
    @drug_pres_line_data_list = drugs["prescription_line"]

    @drug_pres_pie = []
    @drug_disp_pie = []

    (drugs["prescription_pie"] || []).each do |drug, value|
      @drug_pres_pie << [drug,value]
    end
    (drugs["dispensation_pie"] || []).each do |drug, value|
      @drug_disp_pie << [drug,value]
    end


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
    start = Date.today - 6.days
    end_date = Date.today

    highest_frequencies = Observation.find_by_sql("SELECT DISTINCT value_drug, SUM(value_numeric) AS amounts FROM observations "+
                                      " WHERE definition_id in (#{prescription_id}, #{dispensation_id}) AND value_date BETWEEN #{start} AND "+
                                      "  #{end_date} order by amounts DESC LIMIT 10").collect{|x| x.value_drug}


    dispensations = Observation.where(:definition_id => dispensation_id,
                                      :value_drug => highest_frequencies,
                                      :value_date => start..end_date).order("value_date asc")

    prescriptions = Observation.where(:definition_id => prescription_id,
                                      :value_drug => highest_frequencies,
                                      :value_date => start..end_date).order("value_date asc")

    disp_line,pres_line,disp_pie,pres_pie = graph_data_sorter(dispensations,prescriptions)

    data = {"dispensation_line" => disp_line,"dispensation_pie" => disp_pie,
            "prescription_line" => pres_line,"prescription_pie" => pres_pie}

    return data

  end

  def aggregate(days)

    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id

    start = Date.today - 6.days
    end_date = Date.today
    prescriptions = Observation.where(:definition_id => prescription_id, :value_date => start..end_date).order("value_date asc")
    dispensations = Observation.where(:definition_id => dispensation_id,:value_date => start..end_date).order("value_date asc")

    disp_line,pres_line,disp_pie,pres_pie = graph_data_sorter(dispensations,prescriptions,days)

    data = {"dispensation_line" => disp_line,"dispensation_pie" => disp_pie,
            "prescription_line" => pres_line,"prescription_pie" => pres_pie}
    return data
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


