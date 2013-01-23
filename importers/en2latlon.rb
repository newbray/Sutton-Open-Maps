# Convert OSGB36 eastings and northings to WGS84 latitudes and longitudes
# $ ruby en2latlon.rb infile.csv > outfile.csv

require 'csv'
require_relative './OSGB36'

lines = CSV.read(ARGV[0]) # read the whole file into an array of arrays

(0..lines.size - 1).each do |i|
  if i == 0
    easting_col = lines[i].index("X")
    northing_col = lines[i].index("Y")
    lines[i] << "lat"
    lines[i] << "lng"
  else
    ll = OSGB36.en_to_ll(lines[i][easting_col].to_f, lines[i][northing_col].to_f)
    lines[i] << ll[:latitude]
    lines[i] << ll[:longitude]
  end
end

csv_str = CSV.generate do |csv|
  lines.each do |line|
    csv << line
  end
end

puts csv_str
