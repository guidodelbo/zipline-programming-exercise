#!/usr/bin/env ruby

require 'minitest/autorun'
require 'csv'
require 'tempfile'
require_relative './grouping'

class TestPersonMatcher < Minitest::Test
  def setup
    @temp_files = []
  end

  def teardown
    @temp_files.each do |f|
      output_file = f.path.sub('.csv', '_output.csv')
      File.delete(output_file) if File.exist?(output_file)
      f.close!
    end
  end

  def create_temp_csv(content)
    temp_file = Tempfile.new(['test', '.csv'])
    temp_file.write(content)
    temp_file.close
    @temp_files << temp_file

    temp_file.path
  end

  def test_same_email_matching
    csv_content = <<~CSV
      FirstName,LastName,Phone1,Phone2,Email1,Email2,Zip
      John,Doe,(555) 123-4567,(555) 987-6543,john@example.com,,94105
      Jane,Smith,(555) 111-2222,,john@example.com,,94106
      Alice,Johnson,(555) 333-4444,,alice@example.com,,94107
    CSV

    input_file = create_temp_csv(csv_content)
    matcher = PersonMatcher.new('same_email')
    matcher.process_file(input_file)

    output_file = input_file.sub('.csv', '_output.csv')
    output_rows = CSV.read(output_file)

    assert_equal ['person_id', 'FirstName', 'LastName', 'Phone1', 'Phone2', 'Email1', 'Email2', 'Zip'], output_rows[0]

    john_id = output_rows[1][0]
    jane_id = output_rows[2][0]
    alice_id = output_rows[3][0]

    assert_equal john_id, jane_id
    refute_equal john_id, alice_id
    refute_equal jane_id, alice_id
  end

  def test_same_phone_matching
    csv_content = <<~CSV
      FirstName,LastName,Phone1,Phone2,Email1,Email2,Zip
      John,Doe,(555) 123-4567,(555) 987-6543,john@example.com,,94105
      Jane,Smith,(555) 111-2222,(555) 123-4567,jane@example.com,,94106
      Alice,Johnson,(555) 333-4444,,alice@example.com,,94107
    CSV

    input_file = create_temp_csv(csv_content)
    matcher = PersonMatcher.new('same_phone')
    matcher.process_file(input_file)

    output_file = input_file.sub('.csv', '_output.csv')
    output_rows = CSV.read(output_file)

    john_id = output_rows[1][0]
    jane_id = output_rows[2][0]
    alice_id = output_rows[3][0]

    assert_equal john_id, jane_id
    refute_equal john_id, alice_id
    refute_equal jane_id, alice_id
  end

  def test_same_email_or_phone_matching
    csv_content = <<~CSV
      FirstName,LastName,Phone1,Phone2,Email1,Email2,Zip
      John,Doe,(555) 123-4567,,john@example.com,,94105
      Matt,Rogers,(555) 111-2222,,matt@example.com,,94106
      Jane,Smith,(555) 999-8888,,john@example.com,,94106
      Alice,Johnson,(555) 123-4567,,alice@example.com,,94107
    CSV

    input_file = create_temp_csv(csv_content)
    matcher = PersonMatcher.new('same_email_or_phone')
    matcher.process_file(input_file)

    output_file = input_file.sub('.csv', '_output.csv')
    output_rows = CSV.read(output_file)

    john_id = output_rows[1][0]
    matt_id = output_rows[2][0]
    jane_id = output_rows[3][0]
    alice_id = output_rows[4][0]

    assert_equal john_id, jane_id
    assert_equal jane_id, alice_id
    refute_equal john_id, matt_id
  end

  def test_transitive_matching
    csv_content = <<~CSV
      FirstName,LastName,Phone,Email,Zip
      John,Doe,(555) 123-4567,john@example.com,94105
      Jane,Smith,(555) 123-4567,jane@example.com,94106
      Matt,Rogers,(555) 111-2222,matt@example.com,94106
      Alice,Johnson,(555) 999-8888,jane@example.com,94107
    CSV

    input_file = create_temp_csv(csv_content)
    matcher = PersonMatcher.new('same_email_or_phone')
    matcher.process_file(input_file)

    output_file = input_file.sub('.csv', '_output.csv')
    output_rows = CSV.read(output_file)

    john_id = output_rows[1][0]
    jane_id = output_rows[2][0]
    matt_id = output_rows[3][0]
    alice_id = output_rows[4][0]

    # Rows 1, 2, and 4 should have the same person_id due to transitive relationship
    assert_equal john_id, jane_id
    assert_equal jane_id, alice_id
    refute_equal john_id, matt_id
  end

  def test_multiple_emails
    csv_content = <<~CSV
      FirstName,LastName,Phone,Email,Email3,Email10,Zip
      John,Doe,(555) 123-4567,john@example.com,john3@example.com,john10@example.com,94105
      Jane,Smith,(555) 111-2222,jane@example.com,,john3@example.com,94106
      Alice,Johnson,(555) 333-4444,alice@example.com,,,94107
    CSV

    input_file = create_temp_csv(csv_content)
    matcher = PersonMatcher.new('same_email')
    matcher.process_file(input_file)

    output_file = input_file.sub('.csv', '_output.csv')
    output_rows = CSV.read(output_file)

    john_id = output_rows[1][0]
    jane_id = output_rows[2][0]
    alice_id = output_rows[3][0]

    assert_equal john_id, jane_id
    refute_equal john_id, alice_id
  end

  def test_multiple_phones
    csv_content = <<~CSV
      FirstName,LastName,Phone,Phone3,Phone5,Email,Zip
      John,Doe,(555) 123-4567,(555) 333-4444,(555) 999-8888,john@example.com,94105
      Jane,Smith,(555) 333-4444,(555) 777-6666,,jane@example.com,94106
      Alice,Johnson,(555) 444-5555,,,alice@example.com,94107
    CSV

    input_file = create_temp_csv(csv_content)
    matcher = PersonMatcher.new('same_phone')
    matcher.process_file(input_file)

    output_file = input_file.sub('.csv', '_output.csv')
    output_rows = CSV.read(output_file)

    john_id = output_rows[1][0]
    jane_id = output_rows[2][0]
    alice_id = output_rows[3][0]

    assert_equal john_id, jane_id
    refute_equal john_id, alice_id
  end

  def test_case_insensitive_email_matching
    csv_content = <<~CSV
      FirstName,LastName,Phone,Email,Zip
      John,Doe,(555) 123-4567,JOHN@EXAMPLE.COM,94105
      Jane,Smith,(555) 999-8888,john@example.com,94106
      Alice,Johnson,(555) 444-5555,alice@example.com,94107
    CSV

    input_file = create_temp_csv(csv_content)
    matcher = PersonMatcher.new('same_email')
    matcher.process_file(input_file)

    output_file = input_file.sub('.csv', '_output.csv')
    output_rows = CSV.read(output_file)

    john_id = output_rows[1][0]
    jane_id = output_rows[2][0]
    alice_id = output_rows[3][0]

    assert_equal john_id, jane_id
    refute_equal john_id, alice_id
  end

  def test_whitespace_in_emails_and_phones
    csv_content = <<~CSV
      FirstName,LastName,Phone,Email,Zip
      John,Doe," (555) 123-4567 "," john@example.com ",94105
      Jane,Smith,(555) 123-4567,john@example.com,94106
      Alice,Johnson," (555) 444-5555 "," alice@example.com  ",94107
    CSV

    input_file = create_temp_csv(csv_content)
    matcher = PersonMatcher.new('same_email_or_phone')
    matcher.process_file(input_file)

    output_file = input_file.sub('.csv', '_output.csv')
    output_rows = CSV.read(output_file)

    john_id = output_rows[1][0]
    jane_id = output_rows[2][0]
    alice_id = output_rows[3][0]

    assert_equal john_id, jane_id
    refute_equal john_id, alice_id
  end

  def test_empty_rows
    csv_content = "FirstName,LastName,Phone,Email,Zip\n"

    input_file = create_temp_csv(csv_content)
    matcher = PersonMatcher.new('same_email')
    matcher.process_file(input_file)

    output_file = input_file.sub('.csv', '_output.csv')
    output_rows = CSV.read(output_file)

    assert_equal 1, output_rows.length
    assert_equal ['person_id', 'FirstName', 'LastName', 'Phone', 'Email', 'Zip'], output_rows[0]
  end

  def test_empty_file
    csv_content = ''

    input_file = create_temp_csv(csv_content)
    matcher = PersonMatcher.new('same_email')

    error = assert_raises(ArgumentError) do
      matcher.process_file(input_file)
    end

    assert_match(/The input file is empty/, error.message)
  end

  def test_invalid_matching_type
    error = assert_raises(ArgumentError) do
      PersonMatcher.new('invalid_type')
    end

    assert_match(/Invalid matching type. Must be one of: #{PersonMatcher::MATCHING_TYPES.values.join(', ')}/, error.message)
  end

  def test_no_matching_email_field
    csv_content = <<~CSV
      FirstName,LastName,Phone,Zip
      John,Doe,(555) 123-4567,94105
    CSV

    input_file = create_temp_csv(csv_content)
    matcher = PersonMatcher.new('same_email')

    error = assert_raises(ArgumentError) do
      matcher.process_file(input_file)
    end

    assert_match(/No email field found/, error.message)
  end

  def test_no_matching_phone_field
    csv_content = <<~CSV
      FirstName,LastName,Email,Zip
      John,Doe,john@example.com,94105
    CSV

    input_file = create_temp_csv(csv_content)
    matcher = PersonMatcher.new('same_phone')

    error = assert_raises(ArgumentError) do
      matcher.process_file(input_file)
    end

    assert_match(/No phone field found/, error.message)
  end

  def test_required_last_name_field
    csv_content = "FirstName,Phone,Email,Zip\n"

    input_file = create_temp_csv(csv_content)
    matcher = PersonMatcher.new('same_email')

    error = assert_raises(ArgumentError) do
      matcher.process_file(input_file)
    end

    assert_match(/Required name fields missing: LastName/, error.message)
  end

  def test_required_first_name_field
    csv_content = "LastName,Phone,Email,Zip\n"

    input_file = create_temp_csv(csv_content)
    matcher = PersonMatcher.new('same_email')

    error = assert_raises(ArgumentError) do
      matcher.process_file(input_file)
    end

    assert_match(/Required name fields missing: FirstName/, error.message)
  end

  def test_row_length_mismatch
    csv_content = <<~CSV
      FirstName,LastName,Phone,Email,Zip
      John,Doe,(555) 123-4567,john@example.com,94105
      Jane,Smith,(555) 999-8888,jane@example.com,another@example.com,94106
    CSV

    input_file = create_temp_csv(csv_content)
    matcher = PersonMatcher.new('same_email')

    error = assert_raises(ArgumentError) do
      matcher.process_file(input_file)
    end

    assert_match(/Row 3 has 6 values but expected 5 \(matching headers\)/, error.message)
  end

  def test_both_name_fields_missing
    csv_content = "Phone,Email,Zip\n"

    input_file = create_temp_csv(csv_content)
    matcher = PersonMatcher.new('same_email')

    error = assert_raises(ArgumentError) do
      matcher.process_file(input_file)
    end

    assert_match(/Required name fields missing: FirstName, LastName/, error.message)
  end
end
