require_relative '../app'
require 'csv'
require 'pp'
require 'open-uri' # For URL encoding
require 'htmlentities'

# Before running this script with a CSV file, prepare it so:
#   - There is only a single line of column headings on the first line of the file
#   - There are no spaces before or after the column headings
#   - The column headings correspond with the key names in the columns{} hash below
#   - The data starts on line 2

count = 0

if ARGV[0].nil?
  puts "Specify the filename of the CSV file to import on the command line"
  exit
end

layer = Layer.first_or_create :title => "Grit Bins", :slug => 'grit-bins', :icon => 'gritbin.png'
# Uncomment this line if you want to replace rather than add to existing places for this layer
# layer.places.destroy
columns = {}

CSV.foreach(ARGV[0]) do |row|

  count += 1
  
  if (count == 1)
    
    # Get the column headings
    position = 0

    for column in row
      columns[column] = position
      position += 1
    end
  else
    
    unless row[columns['lat']].nil?

      p row
      
      road_clean = row[columns['Road']].strip.downcase.gsub(/\w+/) { |s| s.capitalize } # capitalize first letter of each word
      report_it_url = "http://reportit.sutton.gov.uk/arsys/shared/ri_login.jsp"
      
      coder = HTMLEntities.new
      tweet_text = "https://twitter.com/intent/tweet?text=@SuttonGrit Please refill grit bin #{row[columns['GritBinID']]} at #{road_clean} #{row[columns['Location']]} /via http://suttonmaps.heroku.com/&related=adrianshort,Suttononline"
      twitter_url = URI::encode(coder.encode(tweet_text, :basic, :decimal))
  
      place = Place.first_or_new(
#         http://bhanu.blogspot.co.uk/2007/03/capitalizing-first-letter-of-each-word.html
        'title' =>        road_clean,
        'description' =>  "#{row[columns['Location']]}<br /><br />Need a refill? <a href=\"#{report_it_url}\">Report it online</a> quoting <strong>grit bin number #{row[columns['GritBinID']]}</strong> or <a href=\"#{twitter_url}\">tweet to @SuttonGrit</a>.",
        'lat' =>          row[columns['lat']],
        'lng' =>          row[columns['lng']],
        'layer' =>        layer
      )
  
      unless place.save
        puts "ERROR: Failed to save object"
        place.errors.each do |e|
          puts e
        end
      end
    end
  end
end
