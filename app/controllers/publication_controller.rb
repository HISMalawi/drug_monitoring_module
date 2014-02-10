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

    raise params.inspect
    tmp = params[:publication][:datafile]
    File.open(Rails.root.join('public', 'uploads', tmp.original_filename), 'wb') do |file|
      file.write(tmp.read)
    end

  end
end
