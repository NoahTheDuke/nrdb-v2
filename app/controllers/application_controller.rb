class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper
  include ActionView::Helpers::TextHelper

  # based on https://stackoverflow.com/questions/53869028/how-to-add-404-error-page-in-ruby-on-rails-app
  # rescue_from Exception, with: :render_404
  # rescue_from ActiveRecord::RecordNotFound, with: :render_404
  # rescue_from ActionController::RoutingError, with: :render_404

  # private

  def render_404
    render file: 'public/404.html', layout: false, status: :not_found
  end
end
