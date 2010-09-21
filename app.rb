require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-aggregates'
require 'dm-validations'
require 'dm-migrations'
require 'dm-serializer'
require 'builder'
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

helpers do

  # http://stackoverflow.com/questions/2950234/get-absolute-base-url-in-sinatra
  def base_url
    @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
  end
end

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
  "<?xml version='1.0'?>\n" + Layer.first(:slug => params[:slug]).places.to_xml
end

get '/maps/:slug.kml' do
  @layer = Layer.first(:slug => params[:slug])
  headers "Content-Disposition" => "inline",
    "Content-Type" => "application/vnd.google-earth.kml+xml"

  xml = Builder::XmlMarkup.new( :indent => 2 )
  
  # Output the XML prologue
  xml.instruct!
  
  # Like all XML docs, our KML file has a single root element.
  # In KML it's called <kml>
  xml.kml :xmlns => "http://earth.google.com/kml/2.0" do
    xml.Document do
  
      xml.name "#{@layer.title} in Sutton"
  
      # Common marker style
      xml.Style( :id => "marker" ) do
        xml.IconStyle do
          xml.Icon do
            xml.href base_url + "/icons/#{@layer.icon}"
          end
        end
        xml.PolyStyle do
          xml.color "ffff0000"
        end
      end
  

      for place in @layer.places
  
        xml.Placemark do
        
          # Give all placemarks a common style as specified earlier in the Style block
          xml.styleUrl "#marker"
          
          xml.name place.title
          
          xml.description [ place.address, place.phone, place.description ].compact.join("<br /><br />")
          
          xml.Point do
          
            # KML coords are always longitude, latitude, altitude (in metres)
            xml.coordinates "#{place.lng}, #{place.lat}, 0"
          end
        end
      end
    end  
  end
end

get '/maps/:slug' do
  @layer = Layer.first(:slug => params[:slug])
  haml :layer
end
