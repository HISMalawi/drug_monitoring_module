class HomeController < ApplicationController
  def index
    if session[:user_id].blank?
      render :layout => 'unlogged'
    end
  end

  def grapher

    groups = ["Site", "Drug", "Aggregate"]

    @type = groups[rand(3)]


  end

  def site

  end

  def drug

  end

  def aggregate

  end

end


