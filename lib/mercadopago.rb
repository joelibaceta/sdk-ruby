#mercadopago Integration Library
#Access mercadopago for payments integration
#
#@author @maticompiano
#@contributors @chrismo

require 'rubygems'
require 'json'
require 'uri'
require 'net/http'
require 'net/https'
require 'openssl'
require 'yaml'
require File.dirname(__FILE__) + '/version'

require 'mercadopago/rest_client'
require 'mercadopago/configuration'
require 'mercadopago/ssl_options_patch'

begin
  require "pry"
rescue LoadError
end

module MercadoPago

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.set_debug_logger(debug_logger)
		RestClient.set_debug_logger(debug_logger)
  end

	# Get Access Token for API use
	def self.get_access_token
		if @configuration.access_token
      @configuration.access_token
    else
			app_client_values = {
				'grant_type' => 'client_credentials',
				'client_id' => @configuration.client_id,
				'client_secret' => @configuration.client_secret
			}

			access_data = RestClient.post("/oauth/token", build_query(app_client_values), RestClient::MIME_FORM)

			if access_data['status'] == "200"
				access_data = access_data["response"]
				access_data['access_token']
			else
				raise access_data.inspect
			end
		end
	end

	# Get information for specific payment
	def self.get_payment(id)
		begin
			access_token = self.get_access_token
		rescue => e
			return e.message
		end

		uri_prefix = @configuration.sandbox_mode ? "/sandbox" : ""
    RestClient.get(uri_prefix + "/collections/notifications/" + id + "?access_token=" + access_token)
	end

	def self.get_payment_info(id)
		self.get_payment(id)
	end

	# Get information for specific authorized payment
	def self.get_authorized_payment(id)
		begin
			access_token = get_access_token
		rescue => e
			return e.message
		end

    RestClient.get("/authorized_payments/" + id + "?access_token=" + access_token)
	end

	# Refund accredited payment
	def self.refund_payment(id)
		begin
			access_token = get_access_token
		rescue => e
			return e.message
		end

		refund_status = {"status" => "refunded"}
    RestClient.put("/collections/" + id + "?access_token=" + access_token, refund_status)
	end

	# Cancel pending payment
	def self.cancel_payment(id)
		begin
			access_token = get_access_token
		rescue => e
			return e.message
		end

		cancel_status = {"status" => "cancelled"}
    RestClient.put("/collections/" + id + "?access_token=" + access_token, cancel_status)
	end

	# Cancel preapproval payment
	def self.cancel_preapproval_payment(id)
		begin
			access_token = get_access_token
		rescue => e
			return e.message
		end

		cancel_status = {"status" => "cancelled"}
    RestClient.put("/preapproval/" + id + "?access_token=" + access_token, cancel_status)
	end

	# Search payments according to filters, with pagination
	def self.search_payment(filters, offset=0, limit=0)
		begin
			access_token = get_access_token
		rescue => e
			return e.message
		end

		filters["offset"] = offset
		filters["limit"] = limit

		filters = build_query(filters)

		uri_prefix = @sandbox ? "/sandbox" : ""
    RestClient.get(uri_prefix + "/collections/search?" + filters + "&access_token=" + access_token)
	end

	# Create a checkout preference
	def self.create_preference(preference)
		begin
			access_token = get_access_token
		rescue => e
			return e.message
		end

    RestClient.post("/checkout/preferences?access_token=" + access_token, preference)
	end

	# Update a checkout preference
	def self.update_preference(id, preference)
		begin
			access_token = get_access_token
		rescue => e
			return e.message
		end

    RestClient.put("/checkout/preferences/" + id + "?access_token=" + access_token, preference)
	end

	# Get a checkout preference
	def self.get_preference(id)
		begin
			access_token = get_access_token
		rescue => e
			return e.message
		end

    RestClient.get("/checkout/preferences/" + id + "?access_token=" + access_token)
	end

	# Create a preapproval payment
	def self.create_preapproval_payment(preapproval_payment)
		begin
			access_token = get_access_token
		rescue => e
			return e.message
		end

    RestClient.post("/preapproval?access_token=" + access_token, preapproval_payment)
	end

	# Get a preapproval payment
	def self.get_preapproval_payment(id)
		begin
			access_token = get_access_token
		rescue => e
			return e.message
		end

    RestClient.get("/preapproval/" + id + "?access_token=" + access_token)
	end

	# Generic resource get
	def self.get(uri, params = nil, authenticate = true)
		if not params.class == Hash
			params = Hash.new
		end

		if authenticate
			begin
				access_token = get_access_token
			rescue => e
				return e.message
			end

			params["access_token"] = access_token
		end

		if not params.empty?
			uri << (if uri.include? "?" then "&" else "?" end) << build_query(params)
		end

    RestClient.get(uri)
	end

	# Generic resource post
	def self.post(uri, data, params = nil)
		if not params.class == Hash
			params = Hash.new
		end

		begin
			access_token = get_access_token
		rescue => e
			return e.message
		end

		params["access_token"] = access_token

		if not params.empty?
			uri << (if uri.include? "?" then "&" else "?" end) << build_query(params)
		end

		RestClient.post(uri, data)
	end

	# Generic resource put
	def self.put(uri, data, params = nil)
		if not params.class == Hash
			params = Hash.new
		end

		begin
			access_token = get_access_token
		rescue => e
			return e.message
		end

		params["access_token"] = access_token

		if not params.empty?
			uri << (if uri.include? "?" then "&" else "?" end) << build_query(params)
		end

    RestClient.put(uri, data)
	end

	# Generic resource delete
	def self.delete(uri, params = nil)
		if not params.class == Hash
			params = Hash.new
		end

		begin
			access_token = get_access_token
		rescue => e
			return e.message
		end

		params["access_token"] = access_token

		if not params.empty?
			uri << (if uri.include? "?" then "&" else "?" end) << build_query(params)
		end

		RestClient.delete(uri)
	end

	def self.build_query(params)
		URI.escape(params.collect { |k, v| "#{k}=#{v}" }.join('&'))
	end

end
