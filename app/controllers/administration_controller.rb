class AdministrationController < ApplicationController
  def index
  end
  def add_site

  end
  def list_sites
    sites = YAML.load_file("#{Rails.root}/config/sites.yml")
    @sites = {}
    (sites || []).each do |name, value|
       @sites[name] = {"address" => value.split(":")[0],"port" => value.split(":")[1]}  unless value.blank?
    end
  end
  def edit_site

  end

  def delete_site
    settings = YAML.load_file("#{Rails.root}/config/sites.yml")
    settings.delete params[:site]
    File.open("#{Rails.root}/config/sites.yml",'w'){|f| YAML.dump(settings, f)}
    render :text => "Site details removed"
  end

  def save_site
    settings = YAML.load_file("#{Rails.root}/config/sites.yml")
    if params[:old_site].blank?
      site = Site.find(:first, :conditions => ["name = ? ", params[:site]])
      if site.blank?
        site = Site.create({:name => params[:site]})
        settings[params[:site]] = params[:address]+":"+params[:port]
      else
        return "Site name already exists"
      end
    elsif params[:site] != params[:old_site]
      settings[params[:site]] = settings.delete settings[params[:old_site]]
      settings[params[:site]] = params[:address]+":"+params[:port]
      site = Site.find(:first, :conditions => ["name = ? ", params[:old_site]])
      site.name = params[:site]
      site.save!
    end
    File.open("#{Rails.root}/config/sites.yml",'w'){|f| YAML.dump(settings, f)}
    render :text => "Site details saved successfully"
  end

end
