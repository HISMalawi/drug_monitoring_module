class PublicationController < ApplicationController
  def index
    @publications = Publication.all
  end

  def new

  end

  def edit
    @publications = Publication.all
  end

  def delete

  end

  def save

    if params[:publication][:pub_id].blank?
      @publication = Publication.create(params[:publication])
    else

    end

    redirect_to "/"
  end

end
