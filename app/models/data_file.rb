class DataFile < ActiveRecord::Base
  def self.save(upload, file = nil)
    name = file if !file.nil?

    name = upload['datafile'].original_filename if file.nil?

    directory = "#{Rails.root}/public/data"
    # create the file path
    path = File.join(directory, name)
    # write the file
    File.open(path, "wb") #{ |f| f.write(upload['datafile'].read) }
  end
end