class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  before_filter :authenticate_user

  protected

  def authenticate_user
    return true if User.find(session[:current_user_id])
    access_denied
    return false
  end

  def access_denied
    redirect_to ("/login") and return
  end

end
