class HomeController < ApplicationController
  def index
    if session[:user_id].blank?
      render :layout => 'unlogged'
    end
  end

  def graph

    groups = ["Site", "Drug", "Aggregate"]

    @type = groups[rand(3)]
    @days = []
    start = Date.today - 6.days
    (0..6).each do |i|
      @days << (start + i.days ).strftime('%A')
    end
=begin
    case @type
      when 0
        data,@site = site(@days)
      when 1
        @data = drug()
      when 2
        data = aggregate(@days)
=end
    raise @type.inspect
    data,@site = site(@days)

    @disp_line_data_list = "["
    data["dispensation_line"].each do |d|
      @disp_line_data_list += "{data:"+ d[1].to_json + ", name:'" + d[0]+ "'},"
    end

    @pres_line_data_list = "["
    data["prescription_line"].each do |d|
      @pres_line_data_list += "{data:"+ d[1].to_json + ", name:'" + d[0]+ "'},"
    end
  end

  def site(days)

    site = Site.order("RAND()").first(1).first
    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id

    start = Date.today - 6.days
    end_date = Date.today
    prescriptions = Observation.where(:site_id => site.id, :definition_id => prescription_id, :value_date => start..end_date).order("value_date asc")
    dispensations = Observation.where(:site_id => site.id, :definition_id => dispensation_id,:value_date => start..end_date).order("value_date asc")

    disp_line,pres_line,disp_pie,pres_pie = graph_data_sorter(dispensations,prescriptions,days)

    data = {"dispensation_line" => disp_line,"dispensation_pie" => disp_pie,
            "prescription_line" => pres_line,"prescription_pie" => pres_pie}
    return [data,site.name]
  end

  def drug()
    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id
    start = Date.today - 29.days
    end_date = Date.today

    highest_frequencies = Observation.find_by_sql("SELECT DISTINCT value_drug, SUM(value_numeric) AS amounts FROM observations "+
                                      " WHERE definition_id in (#{prescription_id}, #{dispensation_id}) AND value_date BETWEEN #{start} AND "+
                                      "  #{end_date} order by amounts DESC LIMIT 15").collect{|x| x.value_drug}


    dispensations = Observation.where(:definition_id => dispensation_id,
                                      :value_drug => highest_frequencies,
                                      :value_date => start..end_date).order("value_date asc")

    prescriptions = Observation.where(:definition_id => prescription_id,
                                      :value_drug => highest_frequencies,
                                      :value_date => start..end_date).order("value_date asc")

    disp_line,pres_line,disp_pie,pres_pie = graph_sorter(dispensations,prescriptions)

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

  def graph_data_sorter(dispensations, prescriptions, days)
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


