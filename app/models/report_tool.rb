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
      prescription = Observation.find(:first, :conditions => ["definition_id = ? AND value_date = ? AND value_drug = ? AND site_id = ?",
                                       prescription_id, dispensation.value_date,dispensation.value_drug, dispensation.site_id])
      if prescription.blank?
        issues[dispensation.site.name] << "#{dispensation.get_short_form} has dispensation but no prescriptions on #{dispensation.value_date.strftime('%d %B %Y')}"
      end
    end

    issues
  end


end
