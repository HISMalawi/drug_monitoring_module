class ReportTool < ActiveRecord::Base
  # attr_accessible :title, :body


  def self.find_dispensation_without_prescriptions(start_date ,end_date)
    #This function gets drugs on particular days that where dispensed but not prescribed
    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id

    issues = {}
    #Geting dispensations in duration
    dispensations = Observation.where("definition_id = ? AND value_date >= ? AND value_date <= ?", dispensation_id,start_date,end_date)

    (dispensations || []).each do |dispensation|
      #Getting prescription for specific drug on given date
      prescription = Observation.where("definition_id = ? AND value_date = ? AND value_drug = ? AND site_id = ?",
                                       [prescription_id, dispensation.value_date,dispensation.value_drug, dispensation.site_id]).first
      if prescription.blank?
        issues[dispensation.site.name] << "#{dispensation.get_short_form} has dispensation but no prescriptions on #{dispensation.value_date.strftime('%d %B %Y')}"
      end
    end

    issues
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
          Observation.create_notification(prescription.site_id,prescription.value_date, notice, prescription.get_short_form)
          issues[prescription.site.name] << "#{percent.abs}% more prescriptions than dispensations for #{prescription.get_short_form} on #{prescription.value_date.strftime('%d %B %Y')}"
        elsif percent <= -prescription.site.threshold
          notice = "#{percent.abs}% more dispensations than prescriptions for #{prescription.get_short_form} on #{prescription.value_date.strftime('%d %B %Y')}"
          Observation.create_notification(prescription.site_id,prescription.value_date, notice, prescription.get_short_form)
        end
      end
    end

    dispensations = Observation.where("definition_id = ? AND value_date >= ? AND value_date <= ?", dispensation_id,start_date,end_date)

    (dispensations || []).each do |dispensation|
      #Getting prescription for specific drug on given date
      prescription = Observation.where("definition_id = ? AND value_date = ? AND value_drug = ? AND site_id = ?",
                                       [prescription_id, dispensation.value_date,dispensation.value_drug, dispensation.site_id]).first
      if prescription.blank?
        issues[dispensation.site.name] = [] if issues[dispensation.site.name].blank?
        notice = "#{dispensation.get_short_form} has dispensation but no prescriptions on #{dispensation.value_date.strftime('%d %B %Y')}"
        Observation.create_notification(dispensation.site_id,dispensation.value_date, notice, dispensation.get_short_form)
        issues[dispensation.site.name] << "#{dispensation.get_short_form} has dispensation but no prescriptions on #{dispensation.value_date.strftime('%d %B %Y')}"
      end
    end

    issues
  end


  def self.get_notices_summary(site_id)
    summary = Hash.new(0)
    definitions = Definition.where("name in (?)", ["New", "Investigating"]).collect{|x| x.id}
    notice_defn = Definition.find_by_name("Notice").id

    notices = State.joins("INNER JOIN observations on states.observation_id = observations.observation_id
                                AND observations.site_id = #{site_id} AND states.state in (#{definitions.join(',')})
                                AND observations.definition_id = #{notice_defn}")


    (notices || []).each do |notice|
      summary[notice.state_name] += 1
    end

    return summary
  end
end
