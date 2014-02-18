def start

  prescription_id = Definition.where(:name => "prescription").first.id
  dispensation_id = Definition.where(:name => "Dispensation").first.id
  drugs = ['Stavudine 30 Lamivudine 150','Stavudine 30 Lamivudine 150 Nevirapine 200','Zidovudine 300 Lamivudine 150',
          'Cotrimoxazole 480', 'Stavudine Lamivudine Efavirenz','Zidovudine Lamivudine Nevirapine','Zidovudine 300 Lamivudine 150 Nevirapine 200',
          'Tenofavir 300 Lamivudine 300 and Efavirenz 600'
          ]

  new_sites = [['QECH', 'Central Hospital'],['KCH', 'Central Hospital'], ['ZCH', 'Central Hospital']]
  puts "Create sites"
  (new_sites || []).each do |new_site|
    puts "Creating site #{new_site[0]}"
    Site.create({:name => new_site[0], :description => new_site[1]})
  end

  sites = Site.all

  (sites || []).each do |site|
    puts
    (0..10).each do |i|

      date = Date.today - i.days

      (0..12).each do |p|

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

end

start


