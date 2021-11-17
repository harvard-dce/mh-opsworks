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

    def self.is_online?
      vpsa = Cluster::Zadara.find_vpsa
      vpsa["status"] == "created"
    end

    def self.is_hibernated?
      vpsa = Cluster::Zadara.find_vpsa
      vpsa["status"] == "hibernated"
    end

    def self.check_if_shared_with_another_online_cluster
      return if !storage_config[:nfs_server_host]
      current_stack = Cluster::Stack.find_existing

      # find other stacks configured to use the same nfs_server_host
      shared_with_stacks = Cluster::Stack.all.find_all do |stack|
        if current_stack.id != stack.id
          custom_json = JSON.parse(stack.custom_json)
          custom_json["storage"]["nfs_server_host"] == storage_config[:nfs_server_host]
        end
      end

      # check if those stacks have any online instances
      shared_with_stacks.any? do |stack|
        instances = opsworks_client.describe_instances(stack_id: stack.stack_id).inject([]){ |memo, page| memo + page.instances }
        if instances.any?{|instance| instance.status == "online"}
          puts "The VPSA at #{storage_config[:nfs_server_host]} is shared with stack #{stack.name} which appears to be online"
          true
        end
      end
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
