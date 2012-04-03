module Mandrill
  class API
    # Blank Slate
    instance_methods.each do |m|
      undef_method m unless m.to_s =~ /^__|object_id|method_missing|respond_to?|to_s|inspect|kind_of?|should|should_not/
    end
    
    # Mandrill API Documentation: http://mandrillapp.com/api/docs
    API_VERSION = "1.0"
    API_URL = "https://mandrillapp.com/api"
    AUTH_URL = "https://mandrillapp.com/api-auth/"
    
    # Generate a Mandrill +authorization_url+.
    # Returns a URL to redirect users to so that they will be prompted
    # to enter their Mandrill username and password to authorize a
    # connection between your application and their Mandrill account.
    #
    # If authorized successfully, a POST request will be sent to the
    # +redirect_url+ with a "key" parameter containing the API key for
    # that user's Mandrill account. Be sure to store this key somewhere,
    # as you will need it to run API requests later.
    #
    # If authorization fails for some reason, an "error" parameter will
    # be present in the POST request, containing an error message.
    #
    # == Example
    #
    # redirect_to Mandrill::API.authorization_url("12345","https://example.com/callback")
    #
    def self.authorization_url(app_id, redirect_url)
      "#{AUTH_URL}?id=#{app_id}&redirect_url=#{URI.escape(redirect_url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
    end
    
    # Initialize
    def initialize(api_key, config = {})
      defaults = {
        :api_version => API_VERSION,
        :format => 'json'
      }
      @config = defaults.merge(config).freeze
      @api_key = api_key
    end
    
    # Dynamically find API methods
    def method_missing(api_method, *args) # :nodoc:
      call(api_method, *args)
      if @response.code.to_i == 200
        return "PONG!" if @response.body == "\"PONG!\""
        @config[:format] == 'json' ? JSON.parse(@response.body) : @response.body
      else
        raise(API::Error.new(JSON.parse(@response.body)["code"], JSON.parse(@response.body)["message"]))
      end
    end
    
    # Check the API to see if a method is supported
    def respond_to?(api_method, *args) # :nodoc:
      call(api_method, *args)
      @response.code == 500 ? false : true
    end
    
    # Display the supported methods
    def public_methods # :nodoc:
      [:messages, :senders, :tags, :templates, :urls, :users]
    end
    
    # Call the API
    def call(api_method, *args)
      req_endpoint = "#{API_URL}/#{@config[:api_version]}/#{api_method.to_s}/#{args.first.to_s}.#{@config[:format]}"
      req_body = {:key => @api_key}
      req_body.merge!(args.last) if args.last.is_a?(Hash)
      @response = HTTPI.post(req_endpoint, req_body)
    end
    
    class Error < StandardError
      def initialize(code, message)
        super "(#{code}) #{message}"
      end
    end
  end
end