class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  protected

  def current_user_email
    session[:user_email]
  end

  def logged_in?
    session[:logged_in] == true
  end

  def require_login
    unless logged_in?
      flash[:alert] = "Please log in to access this page."
      redirect_to login_path
    end
  end

  # Make these methods available in views
  helper_method :current_user_email, :logged_in?
end
