namespace :dmm do
 
  desc "Initilised Site Details"
  task :init_site_details => :environment do
   require Rails.root.join('script','init_site_details.rb')
  end
  
  desc "Update Sites"
  task :update_sites => :environment do
    require Rails.root.join('script','update_sites.rb')
  end
  desc "Update Details"
  task :update_details => :environment do
    require Rails.root.join('script','update_details.rb')
  end

end
