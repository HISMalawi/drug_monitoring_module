require 'couchrest_model'
class Site < CouchRest::Model::Base
  property :name, String
  property :description, String
  property :x, String
  property :y, String
  property :ip_address, String
  property :port, String
  property :region, String
  property :threshold, Integer
  property :active, TrueClass, :default => false

  design do
    view :by_name
    view :by_active
  end

  def number_of_patients
=begin
    defn = Definition.find(:first, :conditions => ["name = ?", "Number of patients"]).id
    number = Observation.find(:first,
                              :conditions => ["definition_id = ? AND site_id = ?", defn, self.id],
                              :order => "created_at DESC"
                            ).value_numeric rescue "Unknown"

    return number
=end
  end

  def number_of_art_patients
=begin
    defn = Definition.find(:first, :conditions => ["name = ?", "Patients on ART"]).id
    number = Observation.find(:first,
                              :conditions => ["definition_id = ? AND site_id = ?", defn, self.id],
                              :order => "created_at DESC"
    ).value_numeric rescue "Unknown"

    return number
=end
  end

  def patients_alive
=begin
    defn = Definition.find(:first, :conditions => ["name = ?", "Patients Alive"]).id
    number = Observation.find(:first,
                              :conditions => ["definition_id = ? AND site_id = ?", defn, self.id],
                              :order => "created_at DESC"
    ).value_numeric rescue "Unknown"

    return number
=end
  end

  def self.all_sites
=begin
    sites = Site.all.collect{|x| x.name}
=end
  end

  def self.longitude
    self.x
  end

  def self.latitude
    self.y
  end
end
