module Api

  CONFIG=YAML.load(File.read(Rails.root.join("config","authentication.yml")))

  class User
    include ActiveModel::MassAssignmentSecurity

    attr_accessor :id, :name, :current_task, :profile_img_url

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
      @profile_img_url = CONFIG["profile_img_urls"][@id]
      if @profile_img_url.nil?
        @profile_img_url = "http://placehold.it/260x180"
      end
    end

    def add_current_task!
      Task.all(self).each do |task|
        if task.is_current?
           self.current_task = task.name
           break
        end
      end
      if self.current_task.nil?
        self.current_task = "NOTHING?!?"
      end
    end

  end

  class Task
    include ActiveModel::MassAssignmentSecurity

    TODAY = "today"

    attr_accessor :id, :name, :assignee_status, :completed

    def self.all(user)
      url = "https://app.asana.com/api/1.0/workspaces/#{CONFIG['workspace_id']}/tasks?assignee=#{user.id}&opt_fields=name,assignee_status,completed"
      private_resource = RestClient::Resource.new url, CONFIG['api_key'], ''
      response = private_resource.get
      data = MultiJson.load(response)
      data["data"].map{|u| self.new(u)}
    end

    def initialize(attrs)
      @id = attrs["id"]
      @name = attrs["name"]
      @assignee_status = attrs["assignee_status"]
      @completed = attrs["completed"]
    end

    def is_current?
      if TODAY == self.assignee_status and FALSE == self.completed
        true
      else
        false
      end
    end

  end
end
