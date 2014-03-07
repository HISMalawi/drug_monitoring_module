class ReportTool < ActiveRecord::Base
  # attr_accessible :title, :body

  def self.find_significant_disp_pres_diff(start_date ,end_date)

    #This function gets significant differences between prescriptions and dispensations
    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id

    issues = []
    prescriptions = Observation.where("definition_id = ? AND value_date >= ? AND value_date <= ?", prescription_id,start_date,end_date)

    (prescriptions || []).each do |prescription|
      #getting dispensation on given day for specific drug
      dispensation = Observation.where("definition_id = ? AND value_date = ? AND value_drug = ? AND site_id = ?",
                                       dispensation_id, prescription.value_date,prescription.value_drug, prescription.site_id)
      #Checking existence of dispensation and percentage of difference
      if dispensation.blank?
        issues << "#{prescription.site.name} has prescriptions for #{prescription.value_drug} but no dispensations on #{prescription.value_date.strftime('%d %B %Y')}"
      else
        percent = (((prescription.value_numeric.to_f - dispensation[0].value_numeric.to_f)/prescription.value_numeric.to_f)*100).round(2)
        if percent >= 20.0
          issues << "#{prescription.site.name} has #{percent.abs}% more prescriptions than dispensations for #{prescription.value_drug} on #{prescription.value_date.strftime('%d %B %Y')}"
        elsif percent <= -20.0
          issues << "#{prescription.site.name} has #{percent.abs}% more dispensations than prescriptions for #{prescription.value_drug} on #{prescription.value_date.strftime('%d %B %Y')}"
        end

      end
    end
    issues
  end

  def self.find_dispensation_without_prescriptions(start_date ,end_date)
    #This function gets drugs on particular days that where dispensed but not prescribed
    prescription_id = Definition.where(:name => "prescription").first.id
    dispensation_id = Definition.where(:name => "dispensation").first.id

    issues = []
    #Geting dispensations in duration
    dispensations = Observation.where("definition_id = ? AND value_date >= ? AND value_date <= ?", dispensation_id,start_date,end_date)

    (dispensations || []).each do |dispensation|
      #Getting prescription for specific drug on given date
      prescription = Observation.find(:first, :conditions => ["definition_id = ? AND value_date = ? AND value_drug = ? AND site_id = ?",
                                       prescription_id, dispensation.value_date,dispensation.value_drug, dispensation.site_id])
      if prescription.blank?
        issues << "#{dispensation.site.name} has dispensation for #{dispensation.value_drug} but no prescriptions on #{dispensation.value_date.strftime('%d %B %Y')}"
      end
    end

    issues
  end


end
