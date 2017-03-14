namespace :db do
  desc "Adding default data"
  task :migrate => :environment do
    require Rails.root.join('db','seeds.rb')
  end
end
