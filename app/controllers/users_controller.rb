class UsersController < ApplicationController
  before_filter :admin_required, :only => [:suspend, :unsuspend, :destroy, :purge, :edit]
  before_filter :find_user, :only => [:update, :show, :edit, :suspend, :unsuspend, :destroy, :purge]
  before_filter :require_user, :only => [:index, :settings, :update]

  # Brainbuster Captcha
  # before_filter :create_brain_buster, :only => [:new]
  # before_filter :validate_brain_buster, :only => [:create]

  def index
    users_scope = admin? ? :all_users : :users
    if params[:q]
      @users = current_site.send(users_scope).named_like(params[:q]).paginate(:page => current_page)
    else
      @users = current_site.send(users_scope).paginate(:page => current_page)
    end
  end

  # render new.rhtml
  def new
  end

  def create
    cookies.delete :auth_token
    @user = current_site.users.build(params[:user])    
    @user.save if @user.valid?
    @user.register! if @user.valid?
    unless @user.new_record?
      flash[:notice] = I18n.t 'txt.activation_required', 
        :default => "Thanks for signing up! Please click the link in your email to activate your account."
      redirect_to root_url
    else
      render :action => 'new'
    end
  end

  def settings
    @user = current_user
    current_site
    render :action => "edit"
  end
  
  def edit
    @user = find_user
  end

  def update
    @user = admin? ? find_user : current_user
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = 'User account was successfully updated.'
        format.html { redirect_to(settings_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def activate
    # not sure why this was using a symbol. Let's use the real false.
    user = params[:perishable_token].blank? ? false : current_site.all_users.find_in_state(:first, :pending, :conditions => {:perishable_token => params[:perishable_token]})
    if user
      user.activate!
      session = UserSession.new
      session.credentials = [user, true]
      session.save
    end
    
    if logged_in?
      flash[:notice] = "Signup complete!"
    end
    
    redirect_back_or_default('/')
  end

  def suspend
    @user.suspend! 
    flash[:notice] = "User was suspended."
    redirect_to users_path
  end

  def unsuspend
    @user.unsuspend! 
    flash[:notice] = "User was unsuspended."
    redirect_to users_path
  end

  def destroy
    @user.delete!
    redirect_to users_path
  end

  def purge
    @user.destroy
    redirect_to users_path
  end
  
  def make_admin
    redirect_back_or_default('/') and return unless admin?
    @user = find_user
    @user.roles.delete_all
    params[:user][:role] ||= {}
    params[:user][:role][:user] = 1     # all new accounts have user role 
    params[:user][:role][:admin] = (params[:user][:admin] == "1")
    Role.all.each { |role|
      @user.roles << role unless params[:user][:role][role.name].blank?
    }
    params[:user].delete(:role)
    redirect_to @user
  end

protected
  def find_user
    @user = if admin?
      current_site.all_users.find params[:id]
    elsif params[:id] == current_user.id
      current_user
    else
      current_site.users.find params[:id]
    end or raise ActiveRecord::RecordNotFound
  end

  def authorized?
    admin? || params[:id].blank? || params[:id] == current_user.id.to_s
  end

  def render_or_redirect_for_captcha_failure
    render :action => 'new'
  end
end