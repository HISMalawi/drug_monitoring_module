def start


  month_of_stock_defn = Definition.find_by_name('Month of Stock').id
  stock_level_defn = Definition.find_by_name('Stock Level').id

  drugs = Observation.find_by_sql("SELECT DISTINCT value_drug FROM observations where voided = 0")

  sites = Site.where(:active => 1)

  (sites || []).each do |site|

    puts "calculating for site : #{site.name}"

    (drugs || []).each do |drug|
      month_of_stock = Observation.calculate_month_of_stock(drug.value_drug, site.id)

      unless (month_of_stock.is_a? String ||  month_of_stock.nan? || month_of_stock.to_s.downcase == "infinity")
        puts "Month of stock : #{month_of_stock} for drug #{drug.value_drug} "
        Observation.create({:site_id => site.id,
                            :definition_id => month_of_stock_defn,
                            :value_numeric => month_of_stock.to_f.round(3),
                            :value_drug => drug.value_drug,
                            :value_date => Date.today})
=begin
        stock_level = Observation.calculate_stock_level(drug.value_drug,site.id)

        Observation.create({:site_id => site.id,
                            :definition_id => stock_level_defn,
                            :value_numeric => stock_level.to_f.round(3),
                            :value_drug => drug.value_drug,
                            :value_date => Date.today})
=end

        end
    end

  end
end

start
