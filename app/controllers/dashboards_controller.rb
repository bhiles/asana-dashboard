class DashboardsController < ApplicationController
  def index
    @project = Api::Project.find(1460716045477)
    @project.add_deliverables!
  end
end
