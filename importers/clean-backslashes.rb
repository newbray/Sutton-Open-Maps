require 'app'

for place in Place.all
  unless place.description.nil?
    place.description = place.description.gsub("&#92;", "")
    place.save
  end
end
