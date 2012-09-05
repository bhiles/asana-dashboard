class TodaysController < ApplicationController
  def index
    all_users = Api::User.all
    @date_user_tasks = Api::Task.fetch_grouped_by_completion_date(all_users)
  end
end
