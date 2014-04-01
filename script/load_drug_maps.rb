
def load_drug_map
  facilities = []
  csv_url = "#{Rails.root}/db/drug_mapping.csv"

  FasterCSV.foreach("#{csv_url}", :quote_char => '"',
                    :col_sep =>',', :row_sep =>:auto, :headers=> :first_row) do |drug_map|

    drug_map = DrugMap.where(:full_name => drug_map[0], :short_name => drug_map[1]).first_or_create
  end
end

load_drug_map