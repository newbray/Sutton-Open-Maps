require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-migrations'
require 'dm-serializer'
require 'haml'
require 'open-uri'
require 'csv'

class Layer
  include DataMapper::Resource
  
  property  :id,          Serial
  property  :title,       String,   :length => 255, :required => true
  property  :description, Text
  
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

get '/maps/:id.csv' do
  content_type :csv
  CSV::Writer.generate(STDOUT) do |csv|
    Layer.get(params[:id]).places.each do |place|
      csv << [  ]
    end
  end
#   Layer.get(params[:id]).places.to_csv
end

get '/maps/:id.json' do
  content_type :json
  Layer.get(params[:id]).places.to_json(:methods => 'address')
end

get '/maps/:id.xml' do
  content_type :xml
  headers "Content-Disposition" => "attachment"
  Layer.get(params[:id]).places.to_xml
end

get '/maps/:id' do
  @layer = Layer.get(params[:id])
  haml :layer
end




