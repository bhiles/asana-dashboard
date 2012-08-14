module Api

  CONFIG=YAML.load(File.read(Rails.root.join("config","authentication.yml")))

  class User
    include ActiveModel::MassAssignmentSecurity

    attr_accessor :id, :name, :current_task

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

    def add_current_task!
      Task.all(self).each do |task|
        puts "task is #{task.inspect}"
        if task.is_current?
           self.current_task = task.name
           break
        end
      end
    end

  end

  class Project
    include ActiveModel::MassAssignmentSecurity

    attr_accessor :id, :name, :deliverables

    def self.find(id)
      url = "https://app.asana.com/api/1.0/projects/#{id}"
      private_resource = RestClient::Resource.new url, CONFIG['api_key'], ''
      response = private_resource.get
      data = MultiJson.load(response)
      self.new(data["data"])
    end

    def initialize(attrs)
      @id = attrs["id"]
      @name = attrs["name"]
    end

    def add_deliverables!
      self.deliverables = Deliverable.all_for_project_id(self.id)
    end

  end

  class Deliverable
    include ActiveModel::MassAssignmentSecurity

    attr_accessor :id, :name, :tasks

    def self.all_for_project_id(project_id)
      all_tasks = Task.all_for_project_id(project_id)
      deliverable = empty_deliverable
      tasks = []
      deliverables = []
      all_tasks.each do |single_task|
        if single_task.is_deliverable?
          if !tasks.empty?
            deliverables << self.new(
                {"id" => deliverable.id,
                  "name" => deliverable.name,
                  "tasks" => tasks})
            tasks = []
          end
          deliverable = single_task
        else
          tasks << single_task
        end
      end
      if !tasks.empty?
        deliverables << self.new(
          {"id" => deliverable.id,
            "name" => deliverable.name,
            "tasks" => tasks})
      end
      return deliverables
    end

    def initialize(attrs)
      @id = attrs["id"]
      @name = attrs["name"]
      @tasks = attrs["tasks"]
    end


    def self.empty_deliverable
      self.new({"id" => 0, "name" => nil})
    end

  end

  class Task
    include ActiveModel::MassAssignmentSecurity

    TODAY = "today"
    DELIVERABLE_SUFFIX = ":"

    attr_accessor :id, :name

    def self.all(user)
      url = "https://app.asana.com/api/1.0/workspaces/#{CONFIG['workspace_id']}/tasks?assignee=#{user.id}"
      private_resource = RestClient::Resource.new url, CONFIG['api_key'], ''
      response = private_resource.get
      data = MultiJson.load(response)
      data["data"].map{|u| self.new(u)}
    end

    def self.all_for_project_id(project_id)
      url = "https://app.asana.com/api/1.0/projects/#{project_id}/tasks"
      private_resource = RestClient::Resource.new url, CONFIG['api_key'], ''
      response = private_resource.get
      data = MultiJson.load(response)
      data["data"].map{|u| self.new(u)}
    end

    def initialize(attrs)
      @id = attrs["id"]
      @name = attrs["name"]
      @assignee_status = attrs["assignee_status"]
    end

    def is_current?
      url = "https://app.asana.com/api/1.0/tasks/#{self.id}?opt_fields=name,assignee_status"
      private_resource = RestClient::Resource.new url, CONFIG['api_key'], ''
      response = private_resource.get
      data = MultiJson.load(response)
      puts "data is #{data.inspect}"
      task = data["data"]
      if TODAY == task["assignee_status"]
        true
      else
        false
      end
    end

    def is_deliverable?
      DELIVERABLE_SUFFIX == self.name[-1]
    end

  end
end
