class HomeController < ApplicationController
  def index
    if session[:user_id].blank?
      render :layout => 'unlogged'
    end
  end



end
