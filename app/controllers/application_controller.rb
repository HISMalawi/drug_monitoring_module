class ApplicationController < ActionController::Base
  #protect_from_forgery
  before_filter :check_logged_in, :except => ['login','logout','verify_user' ]



  protected

  def check_logged_in

    if session[:user_id].blank?
      respond_to do |format|
        format.html { redirect_to :controller => 'user',:action => 'login' }
      end
    elsif not session[:user_id].blank?
      User.current = User.find(session[:user_id])
    end
  end
end
