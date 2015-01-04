class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  helper_method :current_user, :current_tenant

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, notice: 'Unauthorized'
  end

  protected

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def current_tenant
    @current_tenant ||= Tenant.find(session[:tenant_id]) if session[:tenant_id]
  end

  def require_webmaster
    unless current_user && current_user.is_webmaster?
      redirect_to root_path, notice: 'Unauthorized'
    end
  end
end
