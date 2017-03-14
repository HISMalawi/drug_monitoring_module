require 'couchrest_model'
class User < CouchRest::Model::Base

  use_database "user"
  def username
    self['_id']
  end

  def username=(value)
    self['_id'] = value
  end

  property :first_name, String
  property :last_name, String
  property :password_hash, String
  property :email, String
  property :active, TrueClass, :default => true
  property :role, String
  property :creator, String

  timestamps!

  cattr_accessor :current_user
  cattr_accessor :current

  def has_role?(role_name)
    self.current.role == role_name ? true : false
  end

  design do
    view :by_active
    view :by_email
  end

  design do
    view :by_username
  end

  before_save do |pass|
    check_password = BCrypt::Password.new(self.password_hash) rescue 'invalid hash'
    self.password_hash = BCrypt::Password.create(self.password_hash) if (check_password == 'invalid hash')
    self.creator = 'admin' if self.creator.blank?
  end

  def password_matches?(plain_password)
    not plain_password.nil? and self.password == plain_password
  end

  def password
    @password ||= BCrypt::Password.new(password_hash)
    rescue BCrypt::Errors::InvalidHash
      Rails.logger.error "The password_hash attribute of User[#{self.username}] does not contain a valid BCrypt Hash."
    return nil
  end

  def password=(new_password)
    @password = BCrypt::Password.create(new_password)
    self.password_hash = @password
  end

end
