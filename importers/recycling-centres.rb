require 'app'
require 'fastercsv'

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

layer = Layer.first_or_create :title => "Recycling Centres", :slug => 'recycling-centres', :icon => 'cycling.png'
columns = {}

FasterCSV.foreach(ARGV[0]) do |row|

  count += 1
  
  if (count == 1)
    
    # Get the column headings
    position = 0

    for column in row
      columns[column] = position
      position += 1
    end
    
    puts columns.inspect

  else
    
    p row

    bits = row[columns['Site']].split(",")

    bits.each do |bit|
      bit.strip!
    end
    
    description = row[columns['description']].gsub("&lt;", "<").gsub("&gt;", ">")

    place = Place.first_or_new(
      'title' =>        bits[0],
      'address1' =>     bits[1],
      'address2' =>     bits[2],
      'city' =>         row[columns['Area']],
      'postcode' =>     row[columns['Postcode']],
      'description' =>  description,
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
