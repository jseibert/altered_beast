# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  helper :all
  helper_method :current_page
  before_filter :set_language
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'e125a4be589f9d81263920581f6e4182'
  
  # Filter password parameter from logs
  filter_parameter_logging :password

  # raised in #current_site
  rescue_from Site::UndefinedError do |e|
    redirect_to new_site_path
  end
  
  def current_page
    @page ||= params[:page].blank? ? 1 : params[:page].to_i
  end
  
  filter_parameter_logging :password, :password_confirmation
  helper_method :current_user_session, :current_user

  private
    def forums
      scope = Forum.for_site(current_site)
      user = current_user
      if !user
        scope = scope.for_public
      elsif !user.admin?
        scope = scope.for_user(user)
      end
      scope
    end
      
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end

    def require_user
      unless current_user
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to new_session_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        flash[:notice] = "You must be logged out to access this page"
        redirect_to root_url
        return false
      end
    end

    def store_location
      session[:return_to] = request.request_uri
    end

    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end
    def set_language
      I18n.locale = :en || I18n.default_locale
    end

end
