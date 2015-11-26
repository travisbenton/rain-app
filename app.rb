require "httparty"
require "json"
require "colorize"



class Rain 
  def initialize
    @threshold = ARGV[1] || 50 # 50% chance
    @sort = ARGV[0] || "below" # show below threshold
    @location = ARGV[2] ? URI.encode(ARGV[2]) : 78702 # Austin by default

    @GOOGLE_API_KEY = ""
    @FORCAST_API_KEY = ""
  end

  def findLocation
    query = {
      :key => @GOOGLE_API_KEY,
      :address => @location
    }
    url = "https://maps.googleapis.com/maps/api/geocode/json"

    request = HTTParty.get(url, :query => query)
    response = JSON.parse(request.body)

    location = response["results"][0]["geometry"]["location"]
    address = response["results"][0]["formatted_address"]

    printRainPct("#{location["lat"]},#{location["lng"]}", address)
  end

  def printRainPct(latLng, address)
    threshold = @threshold.to_i / 100.to_f

    url = "https://api.forecast.io/forecast/#{@FORCAST_API_KEY}/#{latLng}"

    request = HTTParty.get(url)
    response = JSON.parse(request.body)

    # grab first 8 hours of forcast
    hour = response["hourly"]["data"].first(8)

    if @sort == "above"
      output = hour.select { |time| time["precipProbability"] > threshold }
    else 
      output = hour.select { |time| time["precipProbability"] < threshold }
    end

    puts "Showing the weather for #{address}".colorize(:green)
    puts "============================================".colorize(:green)

    output.each do |i|
      time = Time.at(i["time"])
      formattedTime = time.strftime("%l%p")
      formattedPercent = (i["precipProbability"] * 100).to_i
      description = i["summary"]
      temperature = i["temperature"]

      puts "#{formattedTime} - #{formattedPercent}% chance of rain, #{temperature}°F and #{description}".colorize(:green)
    end
  end
end

rain = Rain.new()
rain.findLocation()