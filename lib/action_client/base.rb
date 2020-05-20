 require_dependency "action_client/request"

module ActionClient
  class Base < AbstractController::Base
    abstract!

    include AbstractController::Rendering
    include ActionView::Layouts

    cattr_accessor :defaults,
      instance_accessor: true,
      default: ActiveSupport::OrderedOptions.new

    class << self
      alias_method :client_name, :controller_path

      def default(options)
        options.each do |key, value|
          defaults[key] = value
        end
      end

      def method_missing(method_name, *args)
        if action_methods.include?(method_name.to_s)
          self.new.process(method_name, *args)
        else
          super
        end
      end
    end

    def post(to:)
      path = to
      template_path = self.class.client_name
      template_name = action_name
      template = lookup_context.find(template_name, Array(template_path))
      format = template.format || :json

      body = render(template: template, formats: format)

      ActionClient::Request.new(
        method: :post,
        uri: File.join(URI(defaults.url).to_s, path.to_s),
        body: CGI.unescapeHTML(body),
        headers: {
          "Content-Type": Mime[format].to_s,
        }.merge(defaults.headers),
      )
    end
  end
end
