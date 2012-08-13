class DashboardsController < ApplicationController
  def index
    @users = Api::User.all
  end
end
