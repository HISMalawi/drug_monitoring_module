def start

  prescription_id = Definition.where(:name => "prescription").first.id
  dispensation_id = Definition.where(:name => "Dispensation").first.id
  drugs = ["1A", "1P", "2A","2P", "3A","3P","4A","4P","5A","6A","7A","8A","9P", "Non-STD" ]

  new_sites = [['QECH', 'Central Hospital'],['KCH', 'Central Hospital'], ['ZCH', 'Central Hospital']]
  puts "Create sites"
  (new_sites || []).each do |new_site|
    puts "Creating site #{new_site[0]}"
    Site.create({:name => new_site[0], :description => new_site[1]})
  end

  sites = Site.find(:all, :conditions => ["site_id NOT in (?)",[1,2]])

  (sites || []).each do |site|
    puts
    (0..10).each do |i|

      date = Date.today  - i.days

        (drugs || []).each do |drug|
          Observation.create({:site_id => site.id,
                              :definition_id => prescription_id,
                              :value_numeric => rand(500),
                              :value_drug => drug,
                              :value_date => date
                             })

          Observation.create({:site_id => site.id,
                                :definition_id => dispensation_id,
                                :value_numeric => rand(500),
                                :value_drug => drug,
                                :value_date => date
          })
        end

    end

  end

end

start


