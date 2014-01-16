class UserController < ApplicationController
  def index
  end

  def login
    render :layout => 'unlogged'
  end

  def logout
    session[:user_id] = nil
    User.current = nil
    redirect_to :controller => :home
  end

  def create
  end

  def edit
    @user = User.all
  end

  def edit_user
      @user = User.find(params[:user_id])
  end

  def delete
    user = User.find(params[:user_id])
    user.update_attributes(:voided => true)
    render :text =>  "User successfully voided!" and return
  end

  def verify_user

    state = User.authenticate(params[:username],params[:password])

    if state
      user = User.find_by_username(params[:username])
      session[:user_id] = user.id
      User.current = user
      redirect_to :controller => :home
    end
  end

  def save
    exists = User.find(:first, :conditions => ["voided = 0 AND username = ?", params[:username]]) rescue nil

    if !exists.nil?
      render :text => "Username already taken!" and return
      redirect_to "/user/new"
      return
    end

    new_user = User.new()
    new_user.password = params[:password]
    new_user.username = params[:username]
    new_user.save
    role = Role.find_by_role(params[:role]).id
    new_user_role = UserRole.create({:user_id => new_user.id, :role_id => role})
    render :text =>  "User successfully created!" and return

  end

  def save_edit
    user = User.find(params[:user_id])
    user.update_attributes({:username => params[:username], :password => params[:password]})
    role = Role.find_by_role(params[:role]).id
    user_role = user.user_role
    user_role.update_attributes({:role_id => role})
    render :text => "User successfully updated"
  end
end
