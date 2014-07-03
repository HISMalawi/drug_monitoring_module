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
  new_role = Role.create({:role => role[0], :description => role[1]})
end

puts "Creating default user"

user = User.create({:username => "admin", :password => "test"})
UserRole.create({:user_id => user.id, :role_id => 1})

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
  ["Month of Stock", "Calculated month of stock of a drug at a site"],
  ["Stock Level", "Calculated stock levels for a drug at a site"],
  ["New Delivery", "Drugs just arrived at a site"],
  ["Notice", "Notification of discrepancy in data"],
  ["New", "State for notification"],
  ["Investigating", "State of notification"],
  ["Resolved", "State of notification"]
]

(definitions || []).each do |definition|
  new_definition = Definition.create({:name => definition[0], :description => definition[1]})
end

puts 'loading drug mappings'
`rails runner #{Rails.root}/script/load_drug_maps.rb`