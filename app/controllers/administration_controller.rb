class AdministrationController < ApplicationController
  def index
  end
  def add_site
    @nojquery = true
    @sites = Site.where(:active => false)
  end
  def list_sites
    sites = Site.where(:active => true)
    @sites = {}
    (sites || []).each do |site|
      @sites[site.name] = {"address" => site.ip_address,"port" => site.port}  unless @sites[site.name].blank?
    end
  end
  def edit_site
    @sites = Site.where(:active => true)
    @nojquery = true
  end

  def delete_site
    settings = YAML.load_file("#{Rails.root}/config/sites.yml")
    settings.delete params[:site]
    File.open("#{Rails.root}/config/sites.yml",'w'){|f| YAML.dump(settings, f)}
    render :text => "Site details removed"
  end

  def save_site

    unless params.blank? || !request.post?
      if params[:old_site].blank?
        site = Site.find_by_name(params[:sitename])
        site.update_attributes({
            :name => params[:sitename],
            :site_code => params[:site_code],
            :ip_address => params[:ip_address],
            :port => params[:port],
            :active => true
          }
        )

      elsif
        site = Site.find(:first, :conditions => ["name = ? ", params[:old_site]])
        site.name = params[:sitename]
        site.site_code = params[:site_code]
        site.ip_address = params[:ip_address]
        site.port = params[:port]
        site.threshold = params[:threshold]
        site.active = params[:status]
        site.save
      end
    end
    redirect_to "/"
  end

  def map
    @region = params["region"] rescue nil
    @label = nil

    @region = "blank" if @region.blank?

    case @region.to_s.downcase
    when "centre"
      @label = "Central Region"
    when "north"
      @label = "Northern Region"
    when "south"
      @label = "Southern Region"
    end

    @x = nil
    @y = nil

    if !params["x"].blank?
      @x = params["x"]
    end

    if !params["y"].blank?
      @y = params["y"]
    end

    render :layout => false
  end

  def save_notice_changes
    to_be_resolved = params[:to_be_resolved].split(',')
    to_be_investigated = params[:to_be_investigated].split(',')
    resolved = Definition.where(:name => "Resolved").first.id
    investigating = Definition.where(:name => "Investigating").first.id

    unless (to_be_resolved.blank?)
      to_be_resolved.each do |state_id|
        obs_state = State.find(state_id)
        obs_state.state = resolved
        obs_state.save!
      end
    end

    unless (to_be_investigated.blank?)
      to_be_investigated.each do |state_id|
        obs_state = State.find(state_id)
        obs_state.state = investigating
        obs_state.save!
      end
    end
    render :text => true and return
  end
end
