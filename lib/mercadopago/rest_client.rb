
module MercadoPago

  module RestClient

    class HTTPClient < Net::HTTP
      def self.init(base_uri)
        uri = URI.parse(base_uri)
        http = HTTPClient.new(uri.host, uri.port)
        if uri.scheme == "https"
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.ssl_options = OpenSSL::SSL::OP_NO_SSLv3
        end
        http
      end
    end

    MIME_JSON = 'application/json'
    MIME_FORM = 'application/x-www-form-urlencoded'
    API_BASE_URL = 'https://api.mercadopago.com'

    def self.set_debug_logger(debug_logger)
      @@http.set_debug_output debug_logger
    end

    def self.exec(method, uri, data, content_type)
      if not data.nil? and content_type == MIME_JSON
        data = data.to_json
      end

      @@http = HTTPClient.init(API_BASE_URL)

      headers = {
          'User-Agent' => "mercadopago Ruby SDK v" + MERCADO_PAGO_VERSION,
          'Content-type' => content_type,
          'Accept' => MIME_JSON
      }

      api_result = @@http.send_request(method, uri, data, headers)
      {
          "status" => api_result.code,
          "response" => JSON.parse(api_result.body)
      }
    end

    def self.get(uri, content_type=MIME_JSON)
      exec("GET", uri, nil, content_type)
    end

    def self.post(uri, data = nil, content_type=MIME_JSON)
      exec("POST", uri, data, content_type)
    end

    def self.put(uri, data = nil, content_type=MIME_JSON)
      exec("PUT", uri, data, content_type)
    end

    def self.delete(uri, content_type=MIME_JSON)
      exec("DELETE", uri, nil, content_type)
    end



  end
end