require 'couchrest_model'
class UserRole < CouchRest::Model::Base
  property :username, String
  property :role, String
  timestamps!
end
