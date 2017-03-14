require 'couchrest_model'
class Definition < CouchRest::Model::Base
  property :name, String
  property :description, String

  design do
    view :by_name
  end

  timestamps!
end
