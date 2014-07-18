# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)


puts "Loading defaults"

puts "Creating User roles"
roles =[["Administrator", "This is the system administrator who handles all system functions"],
  ["Other", "Other system user"] ]

(roles || []).each do |role|
  new_role = Role.where({:role => role[0], :description => role[1]}).first_or_create
end

puts "Creating default user"
if User.find_by_username("admin").blank?
  user = User.create({:username => "admin", :password => "test"})
  UserRole.create({:user_id => user.id, :role_id => 1})
end


puts "Creating default definitions"
definitions = [["Prescription", "Describes the number of precriptions"],
  ["Dispensation", "Describes the number of dispensations"],
  ["Number of patients", "Number of patients"],
  ["Patients on ART","Patients on ART" ],
  ["Patients Alive","Patients Alive" ],
  ["Total delivered","Cumulative deliveries" ],
  ["Total prescribed","Precriptions ever" ],
  ["Total dispensed","Dispensations ever" ],
  ["Total removed","Total pills removed [cumulative]" ],
  ["Clinic verification","Physically counted at clinic level" ],
  ["Supervision verification","Physically counted at supervision level" ],
  ["People who received drugs", "Number of people to whom a drug was dispensed"],
  ["People prescribed drug", "Number of people to whom a drug was prescribed"],
  ["Relocation", "Drugs that expired, damaged or were transferred to other locations"],
  ["New Delivery", "Drugs just arrived at a site"],
  ["Notice", "Notification of discrepancy in data"],
  ["New", "State for notification"],
  ["Investigating", "State of notification"],
  ["Resolved", "State of notification"],
  ["Month of Stock", "Calculated month of stock of a drug at a site"],
  ["Stock Level", "Calculated stock levels for a drug at a site"],
  ["HIV Unit Drugs", "List of items required by HIV unit"]
]

(definitions || []).each do |definition|
  new_definition = Definition.where({:name => definition[0], :description => definition[1]}).first_or_create
end

definition = Definition.find_by_name("HIV Unit Drugs").id

puts "Load drug set"
drugs = [ "ABC/3TC (Abacavir and Lamivudine 60/30mg tablet)",
         "AZT/3TC (Zidovudine and Lamivudine 60/30 tablet)",
         "AZT/3TC (Zidovudine and Lamivudine 300/150mg)",
         "AZT/3TC/NVP (60/30/50mg tablet)",
         "AZT/3TC/NVP (300/150/200mg tablet)",
         "d4T/3TC (Stavudine Lamivudine 6/30mg tablet)",
         "d4T/3TC (Stavudine Lamivudine 30/150 tablet)",
         "Triomune baby (d4T/3TC/NVP 6/30/50mg tablet)",
         "d4T/3TC/NVP (30/150/200mg tablet)",
         "EFV (Efavirenz 200mg tablet)",
         "EFV (Efavirenz 600mg tablet)",
         "LPV/r (Lopinavir and Ritonavir 100/25mg tablet)",
         "LPV/r (Lopinavir and Ritonavir 200/50mg tablet)",
         "LPV/r (Lopinavir and Ritonavir syrup)",
         "ATV/r (Atazanavir 300mg/Ritonavir 100mg)",
         "NVP (Nevirapine 200 mg tablet)",
         "TDF/3TC (Tenofavir and Lamivudine 300/300mg tablet","TDF/3TC/EFV (300/300/600mg tablet)",
         "Cotrimoxazole (480mg tablet)",
         "Cotrimoxazole (960mg)", "INH or H (Isoniazid 100mg tablet)", "INH or H (Isoniazid 300mg tablet)"]

(drugs || []).each do |drug|
  DrugSet.where({:definition_id => definition, :drug_name => drug}).first_or_create
end

puts 'loading drug mappings'
`rails runner #{Rails.root}/script/load_drug_maps.rb`