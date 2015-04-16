class ApplicationController < ActionController::Base
  #protect_from_forgery
  before_filter :check_logged_in, :except => ['login','logout','verify_user', 'notices', 'ajax_burdens']

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

  def preferred_units(unit = nil)
    return session[:display_units] if unit.blank?

    if  [30, 60, 90, 120].include?(unit.to_i)
      session[:display_units] = "Tins of #{unit}" if unit.present?
    else
      session[:display_units] = "pills" if unit.present?
    end
  end
end
