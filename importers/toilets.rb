require_relative '../app'
require 'csv'
# require 'pat'

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

layer = Layer.first_or_create :title => "Toilets", :slug => 'toilets', :icon => 'toilets.png'
columns = {}

@days = %w[ mon tue wed thu fri sat sun ]
@facilities = [ 'Male', 'Female', 'Disabled', 'Baby Changing', 'RADAR Key', 'Changing Places' ]

CSV.foreach(ARGV[0]) do |row|

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
    
#     @postcode = Pat.get(row[columns['Post Code']])
        
    desc = '<strong>Open</strong><table>'
    
    for day in @days
      desc += "<tr>"
      if row[columns["#{day}-open"]] == 'no'
        desc += "<td>#{day.capitalize}</td><td>closed</td>"
      else
        desc += "<td>#{day.capitalize}</td><td>#{row[columns["#{day}-open"]]} - #{row[columns["#{day}-close"]]}</td>"
      end
      desc += "</tr>"
    end
    
    desc += "</table><table>"
    
    for facility in @facilities
      desc += "<tr>"
      desc += "<td>#{facility}</td><td>#{row[columns[facility]].downcase}</td>"
      desc += "</tr>"

    end

    desc += "</table>"

    place = Place.first('title' => row[columns['Premises']], 'layer' => layer)

    place.description = desc
    
#     place = Place.first_or_new(
#       'title' =>        row[columns['Premises']],
#       'description' =>  desc,
#       'lat' =>          @postcode['geo']['lat'],
#       'lng' =>          @postcode['geo']['lng'],
#       'address1' =>     row[columns['Address 1']],
#       'address2' =>     nil,
#       'city' =>         row[columns['City']],
#       'postcode' =>     row[columns['Post Code']],
#       'layer' =>        layer
#     )

    unless place.save
      puts "ERROR: Failed to save object"
      place.errors.each do |e|
        puts e
      end
    end
  end
end
