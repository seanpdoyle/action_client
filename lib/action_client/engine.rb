
module ActionClient
  class Engine < ::Rails::Engine
    initializer "action_client.dependencies" do |app|
      ActionClient::Base.append_view_path app.paths["app/views"]
    end

    initializer "action_client.adapters" do
      ActionClient::Base.default adapter: :net_http

      ActionClient::Base.adapters[:net_http] = ActionClient::Adapters::Net::HttpAdapter.new
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
