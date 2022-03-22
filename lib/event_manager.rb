require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_numbers(phone_number)
  phone_number = phone_number.gsub(/\D/,'')
  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == '1'
    phone_number[1..11]
  else
    "Wrong number!"
  end
end

def legislators_by_zipcode(zipcode)
  # sets the google api to get civic info, and the key we are using to access the api
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  # begin rescue for error zipcodes
  begin
    # get legislators by passing in specific info to the api
    # bring down legislators to just officials, not entire array
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  # make a new output director unless and output directory already exists
  Dir.mkdir('output') unless Dir.exist?('output')

  # set filename equal to a standardized filename with id changed
  filename = "output/thanks_#{id}.html"

  # open the filename in write mode, write the form_letter to it
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def parse_date_time(date)
  time = DateTime.strptime(date, "%m/%d/%y %H:%M")
  hour = time.hour
  day_of_week = time.wday
  return [hour, day_of_week]
end

puts 'Event Manager Initialized!'

# use csv's open method to open file, set headers to true to tell the method that the file has headers
# csv can convert headers to symbols for accessing columns - also makes the more uniform
contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

def create_template_letters(contents)
  # set our template letter to the erb template we made
  template_letter = File.read('form_letter.erb')
  # set erb_template to the template_letter
  erb_template = ERB.new template_letter

  # iterate through each line of the file
  contents.each do |row|
    # set name equal to the column of name
    name = row[:first_name]

    # set id equal to the id column (0) of the row we are operating on
    id = row[0]

    # call clean zipcode to clean up zip codes
    zipcode = clean_zipcode(row[:zipcode])

    # call clean phone number to clean phone numbers
    phone_number = clean_phone_numbers(row[:homephone])

    # run legislators by zipcode with the zipcode to return the full officials array from the google api
    legislators = legislators_by_zipcode(zipcode)

    # run the erb template with the variables we have, bind it, and save to form letter
    # binding makes the object an instance of binding
    # an instance of binding knows all the variables within the given scope
    # this gives the form_letter access to legislators, zipcodes, name, and id
    form_letter = erb_template.result(binding)

    # save_thank_you_letter(id, form_letter)
  end
end

def top_hour_day(contents)
  # call top_time to get best time
  all_times = []
  all_days = []
  contents.each do |row|
    day_time = parse_date_time(row[:regdate])
    all_times.push(day_time[0])
    all_days.push(day_time[1])
  end
  most_occurring_time = all_times.max_by { |i| all_times.count(i) }
  most_occurring_day = all_days.max_by { |i| all_times.count(i) }
  
  "The most occuring time was #{most_occurring_time} and the most occuring day was #{most_occurring_day}."
end

p top_hour_day(contents)
