class SprintController < ApplicationController
  def index
    all_users = Api::User.all
    all_users.pop
    all_users.pop
    all_users.pop

    @users_tasks = Api::Task.fetch_sprint_user_tasks(all_users)
    @sprint_date = Api::Task.this_friday
  end
end
