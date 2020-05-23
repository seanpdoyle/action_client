module ActionClient
  class Engine < ::Rails::Engine
    config.action_client = ActiveSupport::OrderedOptions.new

    initializer "action_client.dependencies" do |app|
      ActionClient::Base.append_view_path app.paths["app/views"]
    end

    initializer "action_client.middleware" do
      config.action_client.request_middleware = ActionDispatch::MiddlewareStack.new do |stack|
        stack.use Rack::ContentLength
      end

      config.action_client.response_middleware = ActionDispatch::MiddlewareStack.new do |stack|
        stack.use Rails::Rack::Logger, [ActionClient::Middleware::Logger]
      end
    end

    initializer "action_client.routes" do |app|
      if Rails.env.development?
        app.routes.prepend do
          mount ActionClient::Engine => "/rails/action_client", as: :action_client_engine
        end
      end
    end
  end
end
