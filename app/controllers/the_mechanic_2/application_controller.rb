module TheMechanic2
  class ApplicationController < ActionController::Base
    # Disable CSRF protection for API endpoints
    protect_from_forgery with: :null_session
  end
end
