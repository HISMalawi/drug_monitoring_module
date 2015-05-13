class UserController < ApplicationController
  def index
  end

  def login
    if request.post?
      state = User.authenticate(params[:user]['username'],params[:user]['password'])
      if state
        user = User.find_by_username(params[:user]['username'])
        session[:user_id] = user.id
        User.current = user
        redirect_to :controller => :home
      end
    else
      session[:user_id] = nil
      User.current = nil
    end
  end

  def logout
    session[:user_id] = nil
    User.current = nil
    redirect_to :action => :login
  end

  def create
    @nojquery = true
  end

  def edit
    @user = User.all
    @nojquery = true
  end

  def edit_user
      @user = User.find(params[:user_id])
      @nojquery = true
  end

  def delete
    user = User.find(params[:user_id])
    user.update_attributes(:voided => true)
    render :text =>  "User successfully voided!" and return
  end

  def save

    new_user = User.new()
    new_user.password = params[:password]
    new_user.username = params[:username]
    new_user.save
    role = Role.find_by_role(params[:user_role]).id
    new_user_role = UserRole.create({:user_id => new_user.id, :role_id => role})

    redirect_to "/user/create" and return

  end

  def save_edit
    user = User.find(params[:user_id])
    user.update_attributes({:username => params[:username], :password => params[:password]})
    role = Role.find_by_role(params[:user_role]).id
    user_role = user.user_role
    user_role.update_attributes({:role_id => role})

    redirect_to "/user/edit" and return
  end

  def check_username

      render :text => true and return


  end
end
