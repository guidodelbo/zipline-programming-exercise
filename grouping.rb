#!/usr/bin/env ruby
require 'csv'

class PersonMatcher
  EMAIL_HEADER_PATTERN = /^Email\d*$/
  PHONE_HEADER_PATTERN = /^Phone\d*$/
  FIRST_NAME_PATTERN = /^FirstName$/
  LAST_NAME_PATTERN = /^LastName$/

  MATCHING_TYPES = {
    email: 'same_email',
    phone: 'same_phone',
    email_or_phone: 'same_email_or_phone'
  }.freeze

  def initialize(matching_type)
    unless MATCHING_TYPES.values.include?(matching_type)
      raise ArgumentError, "Invalid matching type. Must be one of: #{MATCHING_TYPES.values.join(', ')}"
    end

    @matching_type = matching_type
    @next_id = 1
    @headers = nil
  end

  def process_file(input_file)
    puts "INFO: Processing #{input_file} using #{@matching_type} matching..."
    rows = []

    if File.empty?(input_file)
      raise ArgumentError, 'The input file is empty'
    end

    CSV.foreach(input_file).with_index(1) do |row, line_number|
      if @headers.nil?
        @headers = row
        validate_headers
        next
      end

      rows << create_record(row, line_number)
    end

    if rows.empty?
      puts 'INFO: No records found to process (file only contains headers)'
      generate_output(input_file, rows)
      return
    end

    puts "INFO: Found #{rows.length} records to process"
    group_records(rows)
    generate_output(input_file, rows)
    puts 'INFO: Processing completed successfully'
  end

  private

  def validate_headers
    has_email = @headers.any? { |h| h.match?(EMAIL_HEADER_PATTERN) }
    has_phone = @headers.any? { |h| h.match?(PHONE_HEADER_PATTERN) }
    has_first_name = @headers.any? { |h| h.match?(FIRST_NAME_PATTERN) }
    has_last_name = @headers.any? { |h| h.match?(LAST_NAME_PATTERN) }

    # Validate required name fields
    unless has_first_name && has_last_name
      missing_fields = []
      missing_fields << 'FirstName' unless has_first_name
      missing_fields << 'LastName' unless has_last_name

      raise ArgumentError, "Required fields missing: #{missing_fields.join(', ')}"
    end

    # Validate required matching type fields
    case @matching_type
    when MATCHING_TYPES[:email]
      raise ArgumentError, 'No email field found' unless has_email
    when MATCHING_TYPES[:phone]
      raise ArgumentError, 'No phone field found' unless has_phone
    when MATCHING_TYPES[:email_or_phone]
      raise ArgumentError, 'No email or phone fields found' unless has_email || has_phone
    end
  end

  def create_record(row, line_number)
    # Validate row length
    unless row.length == @headers.length
      raise ArgumentError, "Row #{line_number} has #{row.length} values but expected #{@headers.length} (matching headers)"
    end

    record = {}

    @headers.each_with_index do |header, index|
      value = row[index]
      # Additional validation could be added here for specific field presence and formats
      record[header] = value
    end

    record['original_row'] = row
    record['person_id'] = nil

    record
  end

  def get_all_emails(record)
    @headers.select { |h| h.match?(EMAIL_HEADER_PATTERN) }
            .map { |h| record[h] }
            .compact
            .reject(&:empty?)
            .map { |email| email.strip.downcase }
  end

  def get_all_phones(record)
    @headers.select { |h| h.match?(PHONE_HEADER_PATTERN) }
            .map { |h| record[h] }
            .compact
            .reject(&:empty?)
            .map { |phone| phone.strip }
  end

  def group_records(records)
    case @matching_type
    when MATCHING_TYPES[:email]
      group_by_email(records)
    when MATCHING_TYPES[:phone]
      group_by_phone(records)
    when MATCHING_TYPES[:email_or_phone]
      group_by_email_or_phone(records)
    end
  end

  def group_by_email(records)
    email_map = {}

    records.each do |record|
      emails = get_all_emails(record)
      matching_group = nil

      emails.each do |email|
        if email_map[email]
          matching_group = email_map[email]
          break
        end
      end

      if matching_group
        record['person_id'] = matching_group
        emails.each { |email| email_map[email] = matching_group }
      else
        record['person_id'] = @next_id
        emails.each { |email| email_map[email] = @next_id }
        @next_id += 1
      end
    end
  end

  def group_by_phone(records)
    phone_map = {}

    records.each do |record|
      phones = get_all_phones(record)
      matching_group = nil

      phones.each do |phone|
        if phone_map[phone]
          matching_group = phone_map[phone]
          break
        end
      end

      if matching_group
        record['person_id'] = matching_group
        phones.each { |phone| phone_map[phone] = matching_group }
      else
        record['person_id'] = @next_id
        phones.each { |phone| phone_map[phone] = @next_id }
        @next_id += 1
      end
    end
  end

  def group_by_email_or_phone(records)
    email_map = {}
    phone_map = {}

    records.each do |record|
      emails = get_all_emails(record)
      phones = get_all_phones(record)
      matching_group = nil

      # Check emails first, then phones, take first match
      emails.each do |email|
        if email_map[email]
          matching_group = email_map[email]
          break
        end
      end

      # Only check phones if no email match found
      if !matching_group
        phones.each do |phone|
          if phone_map[phone]
            matching_group = phone_map[phone]
            break
          end
        end
      end

      if matching_group
        record['person_id'] = matching_group
        emails.each { |email| email_map[email] = matching_group }
        phones.each { |phone| phone_map[phone] = matching_group }
      else
        record['person_id'] = @next_id
        emails.each { |email| email_map[email] = @next_id }
        phones.each { |phone| phone_map[phone] = @next_id }
        @next_id += 1
      end
    end
  end

  def generate_output(input_file, records)
    output_file = input_file.sub('.csv', '_output.csv')

    CSV.open(output_file, 'w') do |csv|
      csv << ['person_id'] + @headers

      records.each do |record|
        csv << [record['person_id']] + record['original_row']
      end
    end

    puts "INFO: Output written to #{output_file}"
  end
end

# Only run the main execution if this file is being run directly (not required/imported)
if __FILE__ == $PROGRAM_NAME
  if ARGV.length != 2
    puts "USAGE: #{$0} <input_file> <matching_type>"
    puts "MATCHING TYPES: #{PersonMatcher::MATCHING_TYPES.values.join(', ')}"
    exit 1
  end

  input_file = ARGV[0]
  matching_type = ARGV[1]

  begin
    matcher = PersonMatcher.new(matching_type)
    matcher.process_file(input_file)
  rescue ArgumentError => e
    puts "ERROR: Invalid data format - #{e.message}"
    exit 1
  rescue => e
    puts "ERROR: #{e.message}"
    exit 1
  end
end
