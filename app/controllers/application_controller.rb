class ApplicationController < ActionController::Base
  before_action :redirect_root_to_hubspot
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_current_agent
  before_action :set_current_account
  before_action :set_current_country
  before_action :set_current_state
  private

  def redirect_root_to_hubspot
    if request.path == "/" && request.host == "reconnector.app"
      redirect_to "https://home.reconnector.app", allow_other_host: true, status: :moved_permanently
    end
  end

  def set_nav_menu_option(menu = controller_name)
    @nav_menu_option = menu.to_sym
  end

  def set_tab_option(tab)
    @tab_option = tab
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:account_id, :first_name, :last_name, :mobile, :phone])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :mobile, :phone])
  end

  private

  def set_current_agent
    if agent_signed_in?
      Current.agent = current_agent
      @current_agent = current_agent
    else
      NilAgent.new
    end
  end

  def set_current_account
    return unless agent_signed_in?

    Current.account = Current.agent.account
    @account ||= current_agent.account
  end

  def set_current_country
    Current.country = @current_agent.current_country if @current_agent.present?
  end

  def set_current_state
    Current.state = @current_agent.current_state if @current_agent.present?
  end
  def after_sign_out_path_for(resource_or_scope)
    new_agent_session_path   # login page for Agent model
  end
  protected

  def verify_account_manager!
    redirect_to agent_root_path unless current_agent.account_manager?
  end

  def after_sign_in_path_for(resource)
    case resource
    when Overlord
      console_root_path       # redirect overlords to /console
    when Agent
      agent_root_path     # example: redirect agents to /dashboard
    else
      super
    end
  end
end
