require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-aggregates'
require 'dm-validations'
require 'dm-migrations'
require 'dm-serializer'
require 'haml'

class Layer
  include DataMapper::Resource
  
  property  :id,          Serial
  property  :title,       String,   :length => 255, :required => true
  property  :description, Text
  property  :icon,        String,   :length => 50
  property  :slug,        String,   :length => 255
    
  has n, :places, :order => [ 'title' ]
end

class Place
  include DataMapper::Resource
  
  property  :id,          Serial
  property  :title,       String,   :length => 255, :required => true
  property  :description, Text
  property  :url,         String,   :length => 255
  property  :lat,         String,   :required => true
  property  :lng,         String,   :required => true
  property  :address1,    String,   :length => 255
  property  :address2,    String,   :length => 255
  property  :city,        String,   :length => 50
  property  :county,      String,   :length => 50
  property  :postcode,    String,   :length => 8
  property  :phone,       String,   :length => 20
  
  belongs_to :layer
  
  def address(separator = "<br />")
    [ @address1, @address2, @city, @county, @postcode ].compact.join(separator)
  end
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db.sqlite3")
DataMapper.auto_upgrade!



get '/' do
  @layers = Layer.all(:order => [:title])
  haml :index
end

get '/maps/:slug.csv' do
  content_type :csv
  Layer.first(:slug => params[:slug]).places.to_csv
end

get '/maps/:slug.json' do
  content_type :json
  headers "Content-Disposition" => "attachment"
  Layer.first(:slug => params[:slug]).places.to_json(:methods => 'address')
end

get '/maps/:slug.xml' do
  content_type :xml
  headers "Content-Disposition" => "attachment"
  Layer.first(:slug => params[:slug]).places.to_xml
end

get '/maps/:slug' do
  @layer = Layer.first(:slug => params[:slug])
  haml :layer
end
