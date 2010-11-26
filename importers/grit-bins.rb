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

layer = Layer.first_or_create :title => "Grit Bins", :slug => 'grit-bins', :icon => 'gritbin.png'
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
    
    unless row[columns['lat']].nil?

      p row
  
      place = Place.first_or_new(
        'title' =>        row[columns['Road']],
        'description' =>  "#{row[columns['Location']]}<br /><br />Grit bin ID: #{row[columns['GritBinID']]}",
        'lat' =>          row[columns['lat']],
        'lng' =>          row[columns['lng']],
        'city' =>         row[columns['Town']],
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
