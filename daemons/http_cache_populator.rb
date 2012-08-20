require ENV["RAILS_ENV_PATH"]
loop {
  all_users = Api::User.all
  all_users.each{|user| user.add_current_task!}
  sleep(10.minutes)
}
