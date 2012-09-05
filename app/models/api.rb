module Api

  CONFIG=YAML.load(File.read(Rails.root.join("config","authentication.yml")))

  def self.http_request(url, overwrite_cache=false)
    unless output = CACHE.get(url) and !overwrite_cache
      private_resource = RestClient::Resource.new url, CONFIG['api_key'], ''
      response = private_resource.get
      output = MultiJson.load(response)
      CACHE.set(url, output)
    end
    return output
  end

  class User
    include ActiveModel::MassAssignmentSecurity

    attr_accessor :id, :name, :current_task, :profile_img_url

    def self.all(overwrite_cache=false)
      url = "https://app.asana.com/api/1.0/workspaces/#{CONFIG['workspace_id']}/users"
      data = Api::http_request(url, overwrite_cache)
      data["data"].map{|u| self.new(u)}
    end

    def initialize(attrs)
      @id = attrs["id"]
      @name = attrs["name"]
      @profile_img_url = CONFIG["profile_img_urls"][@id]
      if @profile_img_url.nil?
        @profile_img_url = "http://placehold.it/160x120"
      end
    end

    def add_current_task!(overwrite_cache=false)
      Task.all(self, overwrite_cache).each do |task|
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

    attr_accessor :id, :name, :assignee_status, :completed, :completed_at

    def self.all(user, overwrite_cache=false)
      url = "https://app.asana.com/api/1.0/workspaces/#{CONFIG['workspace_id']}/tasks?assignee=#{user.id}&opt_fields=name,assignee_status,completed,completed_at"
      data = Api::http_request(url, overwrite_cache)
      data["data"].map{|u| self.new(u)}
    end

    def initialize(attrs)
      @id = attrs["id"]
      @name = attrs["name"]
      @assignee_status = attrs["assignee_status"]
      @completed = attrs["completed"]
      @completed_at = attrs["completed_at"]
    end

    def is_current?
      if TODAY == self.assignee_status and FALSE == self.completed
        true
      else
        false
      end
    end

    def extract_date
      Date.strptime(self.completed_at, '%Y-%m-%d').to_s
    end

    def self.fetch_grouped_by_completion_date(users, overwrite_cache=false)
      grouped_tasks = {}
      users.each do |user|
        self.all(user, overwrite_cache).each do |task|
          if !task.completed_at.nil?
            date = task.extract_date
            grouped_task = grouped_tasks[date]
            if grouped_task.nil?
              grouped_tasks[date] = {user.name => [task]}
            else
              user_tasks = grouped_task[user.name]
              if user_tasks.nil?
                grouped_task[user.name] = [task]
              else
                user_tasks << task
              end
            end
          end
        end
      end

      ordered_tasks = []
      (0..256).each do |num_days|
        date = num_days.day.ago.strftime('%Y-%m-%d')
        grouped_task = grouped_tasks[date]
        if !grouped_task.nil?
          ordered_tasks << {date => grouped_task}
        end
      end

      return ordered_tasks
    end

  end
end
