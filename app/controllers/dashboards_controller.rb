class DashboardsController < ApplicationController
  def index
    @users = Api::User.all
    @users.each{|user| user.add_current_task!}
  end
end
