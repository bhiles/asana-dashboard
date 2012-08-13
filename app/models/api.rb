module Api

  CONFIG=YAML.load(File.read(Rails.root.join("config","authentication.yml")))

  class User
    include ActiveModel::MassAssignmentSecurity

    attr_accessor :id, :name

    def self.all
      url = "https://app.asana.com/api/1.0/workspaces/#{CONFIG['workspace_id']}/users"
      private_resource = RestClient::Resource.new url, CONFIG['api_key'], ''
      response = private_resource.get
      data = MultiJson.load(response)
      data["data"].map{|u| self.new(u)}
    end

    def initialize(attrs)
      @id = attrs["id"]
      @name = attrs["name"]
    end

    def tasks
      # make some call using the id
    end
  end
end
