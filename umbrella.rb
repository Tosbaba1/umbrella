# Write your soltuion here!
require "dotenv/load"
require "http"
require "json"
require "date"
require "active_support/all"
require "awesome_print"
require "pry-byebug"
require "ascii_charts"

gm_key = ENV.fetch("GMAPS_KEY")
ENV.fetch("OPENAI_KEY")
pw_key = ENV.fetch("PIRATE_WEATHER_KEY")

line_width = 40

puts "=" * line_width
puts "Will you need an umbrella today?".center(line_width)
puts "=" * line_width
puts
puts "Where are you currently located?"
user_loc = gets.chomp.capitalize

puts "Checking the weather at #{user_loc}"
gm = "https://maps.googleapis.com/maps/api/geocode/json?address=" + user_loc + "&key=" + gm_key

# Place a GET request to the URL
raw_response = HTTP.get(gm).to_s
parsed_response = JSON.parse(raw_response)
location_hash = parsed_response.fetch("results").first
geometry_hash = location_hash.fetch("geometry")
location_coords = geometry_hash.fetch("location")
lat = location_coords.fetch("lat")
lng = location_coords.fetch("lng")

puts "Your coordinates are #{lat}, #{lng}"

pw ="https://api.pirateweather.net/forecast/#{pw_key}/#{lat},#{lng}"

raw_body = HTTP.get(pw).to_s

#Convert the JSON into a Ruby hash

parsed_body = JSON.parse(raw_body)

currently_hash = parsed_body.fetch("currently")

temp = currently_hash.fetch("temperature")

puts "It is currently #{temp}"

minutely_hash = parsed_body.fetch("minutely")
summary = minutely_hash.fetch("summary")
puts "Next hour: #{summary}"

hourly_data = parsed_body.fetch("hourly").fetch("data")

umbrella_warnings = []

# Loop through the next 12 hours (1 to 12)
(1..12).each do |time|
  hour = hourly_data.fetch(time)
  precip_prob = hour.fetch("precipProbability")

  if precip_prob > 0.1
    percent = (precip_prob * 100)
    umbrella_warnings.push("In #{time} hour(s): #{percent}% chance of precipitation")
  end
end

if umbrella_warnings.any?
  puts "You might want to carry an umbrella!"
  umbrella_warnings.each do |warning|
    puts warning
  end
else
  puts "You probably won’t need an umbrella today."
end


# Prepare chart data for 12 hours
chart_data = (1..12).map do |x|
  hour = hourly_data[x]
  precip_prob = hour.fetch("precipProbability")
  [x, (precip_prob * 100)] # [Hour from now, % chance]
end

puts
puts "Precipitation Probability Over the Next 12 Hours"
puts AsciiCharts::Cartesian.new(chart_data, bar: true, hide_zero: true, title: "Hour vs Precip %").draw
