require 'csv'
def load_drug_map

  unknown = Definition.where(:name => "Unknown").first.id
  type = Hash.new(unknown)

  type["ARV"] = Definition.where(:name => "ARV").first.id
  type["Analgesic"] =  Definition.where(:name => "Analgesic").first.id
  type["Antibiotics"] =  Definition.where(:name => "Antibiotics").first.id
  type["Antifungal"] =  Definition.where(:name => "Antifungal").first.id
  type["Antimalarial"] =  Definition.where(:name => "Antimalarial").first.id
  type["Antiviral"] =  Definition.where(:name => "Antiviral").first.id
  type["Opportunistic infection medicine"] =  Definition.where(:name => "Opportunistic infection medicine").first.id


  puts "got all defn"

  csv_url = "#{Rails.root}/db/drug_mapping.csv"

  CSV.foreach("#{csv_url}", {:col_sep =>',', headers:true}) do |drug_map|

    drug_map = Drug.where(:name => drug_map[0], :short_name => drug_map[1], :category => type[drug_map[2]]).first_or_create
  end
end

load_drug_map