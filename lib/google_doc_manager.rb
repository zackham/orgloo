require "rubygems"
require "google/api_client"
require "google_drive"
require 'yaml'

require_relative 'project_parser'

class GoogleDocManager
  PATH_TO_CONFIG = 'config.yaml'

  def self.connect
    x = new
    x.connect
    x
  end

  def initialize
    @config = YAML.load(File.read(PATH_TO_CONFIG))
    # Authorizes with OAuth and gets an access token.
    @client = Google::APIClient.new(application_name: 'Project Manager', application_version: '0.0.1')
    @auth = @client.authorization
    @auth.client_id = @config['google']['client_id']
    @auth.client_secret = @config['google']['client_secret']
    @auth.scope = "https://www.googleapis.com/auth/drive " 
    @auth.redirect_uri = "urn:ietf:wg:oauth:2.0:oob"
  end

  def connect
    if @config['google']['refresh_token']
      @auth.refresh_token = @config['google']['refresh_token']
      @auth.fetch_access_token!
    else
      print("1. Open this page:\n%s\n\n" % @auth.authorization_uri)
      print("2. Enter the authorization code shown in the page: ")
      @auth.code = $stdin.gets.chomp
      @auth.fetch_access_token!
      @config['google']['refresh_token'] = @auth.refresh_token
      write_config
    end
    access_token = @auth.access_token
    @session = GoogleDrive.login_with_oauth(access_token)
  end

  def fetch_docs(path)
    parts = path.split('/')
    c = @session.collection_by_title(parts.shift)
    while part = parts.shift
      c = c.subcollection_by_title(part)
    end
    c.documents
  end

  private
  def write_config
    File.open(PATH_TO_CONFIG, 'w') {|f| f.write YAML.dump(@config) }
  end
end
