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
end
