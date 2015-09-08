=begin
Written by : Timothy Mtonga

Purpose : Add site details for already existing sites
=end

def start
  sites = {'Kawale' => {"facility_type"=> "Health Centre",
                        "mga"=> "Government/public",
                        "ftype"=> "Urban",
                        "latitude"=> -13.99175,
                        "longitude"=> 33.79757,
                        "facility_id"=> "10358",
                        "region"=> "Central",
                        "zone"=> "Central West"},
           "MPC"=> {"facility_type"=> "ARV Center",
                    "mga"=> "Government/public",
                    "ftype"=> "Urban",
                    "latitude"=> -13.99164,
                    "longitude"=> 33.77561,
                    "facility_id"=> "10375",
                    "region"=> "Central",
                    "zone"=> "Central West"},
           "Likuni"=> {"facility_type"=> "Other Hospital",
                       "mga"=> "Christian Health Association of Malawi (CHAM)",
                       "ftype"=> "Urban",
                       "latitude"=> -14.02683,
                       "longitude"=> 33.70886,
                       "facility_id"=> "10388",
                       "region"=> "Central",
                       "zone"=> "Central West"},
           "QECH"=> {"facility_type"=> "Central Hospital",
                     "mga"=> "Government/public",
                     "ftype"=> "Urban",
                     "latitude"=> -15.80214,
                     "longitude"=> 35.021,
                     "facility_id"=> "10745",
                     "region"=> "South",
                     "zone"=> "South West"}
  }

  (sites || []).each do |site_name, details|
    old_site = Site.find_by_name(site_name)
    old_site.update_attributes(:description => details['facility_type'],
                               :x => details['longitude'],:y => details['latitude'],
                               :active => true)
  end
end
start