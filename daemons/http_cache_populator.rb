require ENV["RAILS_ENV_PATH"]
loop {
  overwrite_cache = true
  all_users = Api::User.all(overwrite_cache)
  all_users.each{|user| user.add_current_task!(overwrite_cache)}
  sleep(10.minutes)
}
