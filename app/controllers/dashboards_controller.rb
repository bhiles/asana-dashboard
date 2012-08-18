class DashboardsController < ApplicationController
  def index
    all_users = Api::User.all
    all_users.each{|user| user.add_current_task!}

    @user_rows = []
    user_row = []
    count = 0
    all_users.each_with_index do |user, index|
      user_row << user
      if (index + 1) % 5 == 0
        @user_rows << user_row
        user_row = []
      else
      end
    end

    if !user_row.empty?
      @user_rows << user_row
    end
  end
end
