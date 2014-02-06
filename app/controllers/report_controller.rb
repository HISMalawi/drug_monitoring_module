class ReportController < ApplicationController

  def index
  end

  def site_list
    @sites = Site.all
  end

end
