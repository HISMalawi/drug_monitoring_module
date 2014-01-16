require 'digest/sha1'
require 'digest/sha2'

class User < ActiveRecord::Base
  require 'digest/sha1'

  validates_presence_of :username, :password
  validates_uniqueness_of :username
  set_primary_key :user_id
  has_one :user_role
  cattr_accessor :current
  before_save :encrypt_password
  self.default_scope :conditions => "#{self.table_name}.voided = 0"

  def self.random_string(len)
    #generat a random password consisting of strings and digits
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

  def encrypt_password
    self.salt = User.random_string(10)
    self.password = encrypt(self.password, self.salt)
  end

  def encrypt(password,salt)
    Digest::SHA1.hexdigest(password+salt)
  end

  def self.authenticate(username, password)

    user = User.find_by_username(username) rescue nil

    if !user.nil?

      salt = Digest::SHA1.hexdigest(password + user.salt)

      if salt == user.password

        return true
      else
        return false
      end

    else

      return false

    end


  end

end
