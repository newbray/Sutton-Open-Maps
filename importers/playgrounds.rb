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

layer = Layer.first_or_create :title => "Playgrounds", :slug => 'playgrounds', :icon => 'playground.png'
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
    
    place = Place.first_or_new(
      'title' =>        row[columns['SITE']],
      'description' =>  nil,
      'lat' =>          row[columns['lat']],
      'lng' =>          row[columns['lng']],
      'address1' =>     row[columns['ADDRESS']],
      'address2' =>     nil,
      'city' =>         nil,
      'postcode' =>     nil,
      'phone' =>        nil,
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
