module Cluster
  class Zadara < Base

    def self.all
      resp_data = JSON.parse(api_request("GET", "vpsas.json").body)
      resp_data["data"]
    end

    def self.find_vpsa
      all.find do |vpsa|
        vpsa["ip_address"] == storage_config[:nfs_server_host]
      end
    end

    def self.hibernate
      vpsa = find_vpsa
      unless vpsa["name"].downcase.match("dev")
        raise VpsaNotHibernatable.new(
            "Refusing to hibernate vpsa '#{vpsa["name"]}': Not a 'dev' vpsa!")
      end
      unless vpsa["status"] == "created"
        raise VpsaStatusError.new("VPSA is not online")
      end
      resp = api_request("POST", "vpsas/#{vpsa["id"]}/hibernate.json")
      if resp.code != "201"
        raise HttpError.new(resp.code, resp.message)
      end
      puts "Success. VPSA '#{vpsa["name"]}' is now hibernating."
    end

    def self.restore
      vpsa = find_vpsa
      unless vpsa["name"].downcase.match("dev")
        raise VpsaNotHibernatable.new(
            "Refusing to restore vpsa '#{vpsa["name"]}': Not a 'dev' vpsa!")
      end
      unless vpsa["status"] == "hibernated"
        raise VpsaStatusError.new("VPSA is already online")
      end
      resp = api_request("POST", "vpsas/#{vpsa["id"]}/restore.json")
      if resp.code != "201"
        raise HttpError.new(resp.code, resp.message)
      end
      puts "Success. VPSA '#{vpsa["name"]}' is now being restored."
    end

    def self.prompt_to(action)
      vpsa = Cluster::Zadara.find_vpsa
      if vpsa
        puts "VPSA '#{vpsa["name"]}' status is '#{vpsa["status"]}'"
        print "\n#{action} the VPSA? [Y/n]: "
        do_action = STDIN.gets.strip.chomp
        do_action.downcase != 'n'
      end
    end

    def self.is_online?
      vpsa = Cluster::Zadara.find_vpsa
      vpsa["status"] == "created"
    end

    def self.is_hibernated?
      vpsa = Cluster::Zadara.find_vpsa
      vpsa["status"] == "hibernated"
    end

    private

    def self.api_request(method, path)
      uri = URI.join(zadara_api_config[:api_endpoint], path)
      api_token = zadara_api_config[:api_token]

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      req = method.upcase == "POST" ?
        Net::HTTP::Post.new(uri) :
        Net::HTTP::Get.new(uri)

      req.add_field("Content-Type", "application/json")
      req.add_field("X-Token", api_token)

      http.request(req)
    end
  end

  class HttpError < StandardError
    attr_reader :code, :message

    def initialize( code, message )
      @code, @message = code, message
    end

    def to_s
      "HTTP request failed (NOK) => #{@code} #{@message}"
    end
  end

  class VpsaNotHibernatable < StandardError; end
  class VpsaStatusError < StandardError; end
end
