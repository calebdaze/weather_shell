#!/bin/bash
w_api_key="x"
g_api_key="x"
#This is so it can remember users input for temperature units
temp_unit_file=".temp_unit"

#Gets the IP of the user
get_ip() {
    current_ip=$(curl -s "http://checkip.dyndns.org/" | grep -o -E "[0-9\.]+")
}
#Fetch geolocation data based on IP
get_geolocation_data() {
    #Use ipbase.com API to get geolocation data for the current IP
    geolocation_data=$(curl -s "https://api.ipbase.com/v2/info?ip=${current_ip}" -H "apikey:${g_api_key}")
    lat=$(echo ${geolocation_data} | jq -r '.data.location.latitude')
    lon=$(echo ${geolocation_data} | jq -r '.data.location.longitude')
}
#Calls the ip and geolocation once
get_ip
get_geolocation_data
#Get the temp from the API
get_temp_unit() {
    if [[ -f "$temp_unit_file" ]]; then
        unit=$(cat "$temp_unit_file")
    else
        unit="imperial"  # Default to Fahrenheit (imperial units)
    fi
}
#Saves the users input
set_temp_unit() {
    echo "$1" > "$temp_unit_file"
}
#Function to get each day of a week
get_day_of_week() {
    case $1 in
        0) echo "Sun" ;;
        1) echo "Mon" ;;
        2) echo "Tue" ;;
        3) echo "Wed" ;;
        4) echo "Thu" ;;
        5) echo "Fri" ;;
        6) echo "Sat" ;;
    esac
}
#Get the new weather data
future_data() {
    FOREAPI=$(curl -s "api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&appid=${w_api_key}&units=${unit}")
    #Figure out the dates from the current date
    day1_date=$(date --date="1 day" +%Y-%m-%d)
    day2_date=$(date --date="2 days" +%Y-%m-%d)
    day3_date=$(date --date="3 days" +%Y-%m-%d)
    #Extract forecast data for each day
    day1_temp=$(echo "$FOREAPI" | jq -r ".list[] | select(.dt_txt | startswith(\"$day1_date\")) | .main.temp" | head -n 1)
    day2_temp=$(echo "$FOREAPI" | jq -r ".list[] | select(.dt_txt | startswith(\"$day2_date\")) | .main.temp" | head -n 1)
    day3_temp=$(echo "$FOREAPI" | jq -r ".list[] | select(.dt_txt | startswith(\"$day3_date\")) | .main.temp" | head -n 1)
    day1_desc=$(echo "$FOREAPI" | jq -r ".list[] | select(.dt_txt | startswith(\"$day1_date\")) | .weather[0].description" | head -n 1)
    day2_desc=$(echo "$FOREAPI" | jq -r ".list[] | select(.dt_txt | startswith(\"$day2_date\")) | .weather[0].description" | head -n 1)
    day3_desc=$(echo "$FOREAPI" | jq -r ".list[] | select(.dt_txt | startswith(\"$day3_date\")) | .weather[0].description" | head -n 1)
    #Get the names of the days
    day1_name=$(get_day_of_week $(date --date="$day1_date" +%w))
    day2_name=$(get_day_of_week $(date --date="$day2_date" +%w))
    day3_name=$(get_day_of_week $(date --date="$day3_date" +%w))
    #Print the weather forecast for the next 3 days
    echo "Now the temperature for the next three days:"
    echo "On $day1_name, $day1_date the Temperature will be $day1_temp° with it being $day1_desc outside!"
    echo "On $day2_name, $day2_date the Temperature will be $day2_temp° with it being $day2_desc outside!"
    echo "On $day3_name, $day3_date the Temperature will be $day3_temp° with it being $day3_desc outside!"
}
#Function for getting the present weather variables
present_data()
{
    #Getting all the variables
    WAPI=$(curl -s "https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${w_api_key}&units=${unit}")
    description=$(echo $WAPI | jq -r '.weather[0].description')
    present_temp=$(echo $WAPI | jq -r '.main.temp')
    present_wind=$(echo $WAPI | jq -r '.wind.speed')
    present_rain=$(echo $WAPI | jq -r '.rain."1h" // .rain."3h" // "0"')
    present_temp=$(printf "%.0f" "$present_temp")
    #Starts the present code
    echo "Todays weather has $description with a wind speed of $present_wind mph".
    #Different messages depending on the temp. Makes it have "personality"
    if [[ "$present_temp" -lt 60 ]]; then
        echo "Make sure to bring a jacket outside! The Temperature is $present_temp°!"
    elif [[ "$present_temp" -ge 60  && "$present_temp" -lt 90 ]]; then
        echo "Its going to be a good day outside! Temperature is $present_temp°!"
    else
        echo "Also have I mentioned that it's HOT?! Temperature is $present_temp°!"
    fi
    #Different messages depending on the rain. OpenWeather only does it for the next hour
    if [[ "$present_rain" -gt 0 ]]; then
        echo "It seems like we will get rain within the next hour with a precipitation of around $rain."
    else
        echo "It seems like it will be dry (at least for the next hour :P)"
    fi
}
#Calling all the FUNctions (haha)
get_temp_unit
present_data
future_data
#Doing this so if I want to add more options I just have to change a if statement
echo "Press 'q' to quit the program or press 'c' to change your prefered unit"
while true; do
    read -n 1 -s key
    if [[ "$key" == "q" ]]; then
        break
    elif [[ "$key" == "c" ]]; then
        if [[ "$unit" == "imperial" ]]; then
            clear
            unit="metric"
            set_temp_unit "metric"
            echo "Temperature unit changed to Celsius!"
            present_data
            future_data
        else
            clear
            unit="imperial"
            set_temp_unit "imperial"
            echo "Temperature unit changed to Fahrenheit!"
            present_data
            future_data
        fi
    else
        echo "Bro did not type q or c"
    fi
done
