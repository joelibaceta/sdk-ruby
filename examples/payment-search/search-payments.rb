require 'rubygems'
require 'rack'
$LOAD_PATH << '../../lib'
require 'mercadopago.rb'

class IPN
  def call(env)

		MercadoPago.configure do |config|
			config.client_id     = "CLIENT_ID"
			config.client_secret = "CLIENT_SECRET"
			config.sandbox_mode  = true
		end

		# Sets the filters you want
		filters = Hash["site_id" => "MLA", "external_reference"=>"Bill001"]

		# Search payment data according to filters
		searchResult = MercadoPago.search_payment(filters)

		# Show payment information
		html = searchResult.inspect

		return [200, {'Content-Type' => 'text/html'}, [html]]
	end
end

Rack::Handler::WEBrick.run(IPN.new, :Port => 9000)
