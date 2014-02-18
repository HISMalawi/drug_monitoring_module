class Site < ActiveRecord::Base
  set_primary_key :site_id

  def number_of_patients
    defn = Definition.find(:first, :conditions => ["name = ?", "Number of patients"]).id
    number = Observation.find(:first,
                              :conditions => ["definition_id = ? AND site_id = ?", defn, self.id],
                              :order => "created_at DESC"
                            ).value_numeric rescue "Unknown"

    return number
  end

  def number_of_art_patients
    defn = Definition.find(:first, :conditions => ["name = ?", "Patients on ART"]).id
    number = Observation.find(:first,
                              :conditions => ["definition_id = ? AND site_id = ?", defn, self.id],
                              :order => "created_at DESC"
    ).value_numeric rescue "Unknown"

    return number
  end

  def patients_alive
    defn = Definition.find(:first, :conditions => ["name = ?", "Patients Alive"]).id
    number = Observation.find(:first,
                              :conditions => ["definition_id = ? AND site_id = ?", defn, self.id],
                              :order => "created_at DESC"
    ).value_numeric rescue "Unknown"

    return number
  end

  def self.all_sites
    sites = Site.all.collect{|x| x.name}
  end

end
