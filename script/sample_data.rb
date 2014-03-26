def start

  prescription_id = Definition.where(:name => "prescription").first.id
  dispensation_id = Definition.where(:name => "Dispensation").first.id
  relocation_id = Definition.where(:name => "relocation").first.id
  drug_given_to_id = Definition.where(:name => "People who received drugs").first.id
  drug_prescribed_id = Definition.where(:name => "People prescribed drug").first.id

  drugs = ["1A", "1P", "2A","2P", "3A","3P","4A","4P","5A","6A","7A","8A","9P", "Non-STD" ]



  site = Site.first

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

          Observation.create({:site_id => site.id,
                              :definition_id => relocation_id,
                              :value_numeric => rand(500),
                              :value_drug => drug,
                              :value_date => date
                             })

          Observation.create({:site_id => site.id,
                              :definition_id => drug_given_to_id,
                              :value_numeric => rand(500),
                              :value_drug => drug,
                              :value_date => date
                             })

          Observation.create({:site_id => site.id,
                              :definition_id => drug_prescribed_id,
                              :value_numeric => rand(500),
                              :value_drug => drug,
                              :value_date => date
                             })
        end

    end



end

start


