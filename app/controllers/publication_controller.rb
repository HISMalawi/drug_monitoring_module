class PublicationController < ApplicationController
  def index
    @publications = Publication.all
  end

  def new

  end

  def edit

  end

  def delete

  end

  def save

     @publication = Publication.create(params[:publication])
    redirect_to "/"
  end

end
