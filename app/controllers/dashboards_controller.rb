class DashboardsController < ApplicationController
  def index
    @project = Api::Project.find(1410299255548)
    @project.add_deliverables!
  end
end
