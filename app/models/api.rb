class Api

  CONFIG=YAML.load(File.read(Rails.root.join("config","authentication.yml")))

  def users
    url = "https://app.asana.com/api/1.0/workspaces/#{CONFIG['workspace_id']}/users"
    puts "URL is #{url.inspect}"
    private_resource = RestClient::Resource.new url, CONFIG['api_key'], ''
    json = private_resource.get
    MultiJson.load(json)["data"]
  end

end
