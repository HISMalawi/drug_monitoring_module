def start

  sites = Site.all

  defn = Definition.find(:first, :conditions => ["name = ?", "Number of patients"]).id

  (sites || []).each do |site|

    Observation.create({:site_id => site.id,
                        :definition_id => defn,
                        :value_numeric => rand(5000),
                        :value_date => Date.today
                       })

  end

end

start