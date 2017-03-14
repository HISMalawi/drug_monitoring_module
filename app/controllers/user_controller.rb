class UserController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:authenticate, :create, :delete_me, :update_field, :recover_password]
  before_filter :authenticate_user, :except => [:login, :authenticate, :create, :recover_password]

  def new
    render :layout => "users_menu"
  end

  def create
    available_user = User.find(params[:username])
    if available_user.blank?
      unless (params[:password] == params[:password_confirm])
        flash[:error] = "Unale to create user account. Password mismatch!!"
        redirect_to(users_login_path) and return if params[:from_login]
        redirect_to(users_new_user_path) and return
      end
      user = User.new
      user.username = params[:username]
      user.password_hash = params[:password]
      user.first_name = params[:first_name]
      user.last_name = params[:last_name]
      user.email = params[:email]
      if user.save
        flash[:notice] = "Your user account has been successfully created"
        redirect_to(users_login_path) and return if params[:from_login]
        redirect_to(users_new_user_path) and return
        redirect_to('/') and return
      else
        flash[:error] = "There was an error creating your account"
        redirect_to(users_login_path) and return if params[:from_login]
        redirect_to(users_new_user_path) and return
      end

    else
      flash[:error] = "Unable to create user. Username already exists"
      redirect_to(users_login_path) and return if params[:from_login]
      redirect_to(users_new_user_path) and return
    end
  end


  def login
    render :layout => false
  end

  def user_menu
    render :layout => "users_menu"
  end

  def authenticate
    @user = User.find(params[:user][:username])
    unless @user.blank?
      if @user.password == params[:user][:password]
        #flash[:notice] = "Welcome #{params[:username]}"
        session[:current_user_id] = @user.id
        User.current_user = @user
        User.current = @user
        redirect_to ('/') and return
      else
        flash[:error] = 'Wrong username/password combination'
        redirect_to ("/login") and return
      end
    else
      flash[:error] = 'Wrong username/password combination'
      redirect_to ("/login") and return
    end
  end

  def logout
    session[:current_user_id] = nil
    User.current_user = nil
    flash[:notice] = 'You have been logged out.'
    redirect_to ("/login") and return
  end

  def users_menu

  end

  def new_user

  end

  def edit_user
    unless params[:user_id].blank?
      @user = User.find(params[:user_id])
    end
    @active_users = User.by_active.key(true)
  end

  def delete_user
    @active_users = User.by_active.key(true)
  end
end
