class DashboardsController < ApplicationController
  def index
    @users = Api.new.users
  end
end
