require 'csv'

def csv_input_filename
  'AU_postcode_file_31052021.csv'
end

def csv_output_filename
  'AU_postcode_file_31052021.output.csv'
end

csv_input = File.read(csv_input_filename)
csv = CSV.parse(csv_input, encoding: 'UTF-8', headers: true)

csv_output = CSV.open(csv_output_filename, 'w', headers: true) do |output|
  csv.each do |row|
    new_row = row
    new_row['Country'] = 'Australia'
    output << new_row
  end
end