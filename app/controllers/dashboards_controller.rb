class DashboardsController < ApplicationController
  def index
    all_users = Api::User.all
    @users = []
    @users << all_users.pop
    @users << all_users.pop
    @users << all_users.pop
    @users << all_users.pop
    @users << all_users.pop

    #@tasks = @users.each{|user| Api::Task.currently_working_on(user)}
    @users.each{|user| user.add_current_task!}
  end
end
