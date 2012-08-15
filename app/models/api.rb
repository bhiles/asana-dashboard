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
      self.deliverables.each do |deliverable|
        deliverable.tasks.each do |task|
          task.extract_deliverable!
          puts "Task is #{task.inspect}"
        end
      end
    end

  end

  class Deliverable
    include ActiveModel::MassAssignmentSecurity

    attr_accessor :id, :name, :tasks, :man_hours

    def self.all_for_project_id(project_id)
      all_tasks = Task.all_for_project_id(project_id)
      deliverable = empty_deliverable
      tasks = []
      man_hours = 0
      deliverables = []
      all_tasks.each do |single_task|
        if single_task.is_deliverable?
          if !tasks.empty?
            deliverables << self.new(
                {"id" => deliverable.id,
                  "name" => deliverable.name,
                  "tasks" => tasks,
                  "man_hours" => man_hours})
            tasks = []
            man_hours = 0
          end
          deliverable = single_task
        else
          tasks << single_task
          man_hours += single_task.hours
        end
      end
      if !tasks.empty?
        deliverables << self.new(
          {"id" => deliverable.id,
            "name" => deliverable.name,
            "tasks" => tasks,
            "man_hours" => man_hours})
      end
      return deliverables
    end

    def initialize(attrs)
      @id = attrs["id"]
      @name = attrs["name"]
      @tasks = attrs["tasks"]
      @man_hours = attrs["man_hours"]
    end


    def self.empty_deliverable
      self.new({"id" => 0, "name" => nil})
    end

    def self.find_deliverable_and_tasks(project_id, deliverable_id)
      project_deliverables = all_for_project_id(project_id)
      #puts "Project Deliverables are #{project_deliverables.inspect}"
      specific_deliverable = nil
      project_deliverables.each do |deliverable|
        puts "input id #{deliverable_id.inspect} vs obj id #{deliverable.id.inspect}"
        if deliverable_id == deliverable.id
          specific_deliverable = deliverable
        end
      end
      return specific_deliverable
    end

  end

  class Task
    include ActiveModel::MassAssignmentSecurity

    TODAY = "today"
    DELIVERABLE_SUFFIX = ":"

    attr_accessor :id, :name, :notes, :deliverable, :hours

    def self.all(user)
      url = "https://app.asana.com/api/1.0/workspaces/#{CONFIG['workspace_id']}/tasks?assignee=#{user.id}"
      private_resource = RestClient::Resource.new url, CONFIG['api_key'], ''
      response = private_resource.get
      data = MultiJson.load(response)
      data["data"].map{|u| self.new(u)}
    end

    def self.all_for_project_id(project_id)
      url = "https://app.asana.com/api/1.0/projects/#{project_id}/tasks?opt_fields=name,notes"
      private_resource = RestClient::Resource.new url, CONFIG['api_key'], ''
      response = private_resource.get
      data = MultiJson.load(response)
      data["data"].map{|u| self.new(u)}
    end

    def initialize(attrs)
      @id = attrs["id"]
      @name = attrs["name"]
      @notes = attrs["notes"]
      @hours = Task.extract_hours(attrs["name"])
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

    def extract_deliverable!
      matches = /https:\/\/app\.asana\.com\/0\/(\d+)\/(\d+)/.match(self.notes)
      puts "matches are #{matches.inspect}"
      if !matches.nil?
        project_id = matches[1].to_i
        deliverable_id = matches[2].to_i
        self.deliverable = Deliverable.find_deliverable_and_tasks(project_id, deliverable_id)
        puts "deliverables is #{self.deliverable.inspect}"
      end
    end

    def self.extract_hours(text)
      matches = /^{(\d*.?\d+)([dhm])}/.match(text)
      if matches.nil?
        return 0
      end
      quantity = matches[1].to_r
      unit = matches[2]
      if "h" == unit
        conversion = 1
      elsif "d" == unit
        conversion = 24
      else
        conversion = 0
      end
      (quantity * conversion).to_i
    end

  end
end
