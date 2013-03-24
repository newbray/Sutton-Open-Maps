require 'sinatra'
require 'data_mapper'
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
  property  :address,     String # overridden by address() method; this ensures the method is included in to_json calls etc.
  
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
  @first_layer = Layer.first(:order => [:title])
  haml :layer, :layout => :map, :locals => { :first_layer => @first_layer }
end

get '/data' do
  @layers = Layer.all(:order => [:title])
  haml :data, :layout => :static
end

# get '/maps/:slug.csv' do
#   content_type :csv
#   
#   l = Layer.first(:slug => params[:slug])
#   
#   output = "id,title,address1,address2,city,county,postcode,phone,description,lat,lng\n"
#   
#   for place in l.places
#     output += sprintf("#{place.id.to_s},#{place.title},#{place.address1},#{place.address2},#{place.city},#{place.county},#{place.postcode},#{place.phone},\"%s\",#{place.lat},#{place.lng}\n", place.description.gsub(/<br \/>/, "\n"))
#   end
#   
#   output
# end

get '/maps/:slug.json' do
  content_type :json
  headers "Content-Disposition" => "attachment"
  Layer.first(:slug => params[:slug]).to_json(:methods => [ :places ])
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
  

      @layer.places.each do |place|
  
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

get '/maps/:slug.rss' do
  @layer = Layer.first(:slug => params[:slug])
  headers "Content-Disposition" => "inline", "Content-Type" => "application/rss+xml"

  xml = Builder::XmlMarkup.new(:indent => 2)
  
  # Output the XML prologue
  xml.instruct!
  
  xml.rss :version => "2.0", :"xmlns:atom" => "http://www.w3.org/2005/Atom", :"xmlns:georss" => "http://www.georss.org/georss" do
    xml.channel do
  
      xml.title "#{@layer.title} in Sutton"
      xml.link base_url
      xml.description
      # xml.link :href => "#", :rel => "self", :type => "application/rss+xml" # http://stackoverflow.com/a/9899827/1143712
  
      @layer.places.each do |place|
        xml.item do
        
          xml.title place.title
          xml.link base_url + "/#"
          xml.description [ place.address, place.phone, place.description ].compact.join("\n")
          xml.georss :point, "#{place.lat} #{place.lng}"
          xml.guid "%s/places/%s" % [ base_url, place.id ]
        end
      end
    end  
  end
end
