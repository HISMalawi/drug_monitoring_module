require 'csv'
def load_drug_map

  #unknown = Definition.where(:name => "Unknown").first.id
  unknown = Definition.by_name.key("Unknown").first.id
  type = Hash.new(unknown)

  #type["ARV"] = Definition.where(:name => "ARV").first.id
  type["ARV"] = Definition.by_name.key("ARV").first.id
  #type["Analgesic"] =  Definition.where(:name => "Analgesic").first.id
  type["Analgesic"] =  Definition.by_name.key("Analgesic").first.id
  #type["Antibiotics"] =  Definition.where(:name => "Antibiotics").first.id
  type["Antibiotics"] =  Definition.by_name.key("Antibiotics").first.id
  #type["Antifungal"] =  Definition.where(:name => "Antifungal").first.id
  type["Antifungal"] =  Definition.by_name.key("Antifungal").first.id
  #type["Antimalarial"] =  Definition.where(:name => "Antimalarial").first.id
  type["Antimalarial"] =  Definition.by_name.key("Antimalarial").first.id
  #type["Antiviral"] =  Definition.where(:name => "Antiviral").first.id
  type["Antiviral"] =  Definition.by_name.key("Antiviral").first.id
  #type["Opportunistic infection medicine"] =  Definition.where(:name => "Opportunistic infection medicine").first.id
  type["Opportunistic infection medicine"] =  Definition.by_name.key("Opportunistic infection medicine").first.id

  puts "got all defn"

  csv_url = "#{Rails.root}/db/drug_mapping.csv"

  CSV.foreach("#{csv_url}", {:col_sep =>',', headers:true}) do |drug_map|
    drug = Drug.by_full_name.key(drug_map[0]).last
    drug = Drug.by_short_name.key(drug_map[1]).last if drug.blank?
    
    if drug.blank?
      drug = Drug.new
      drug.full_name = drug_map[0]
      drug.short_name = drug_map[1]
      drug.category = type[drug_map[2]]
      drug.save
    end
    #drug_map = Drug.where(:full_name => drug_map[0], :short_name => drug_map[1], :category => type[drug_map[2]]).first_or_create
  end
end

load_drug_map