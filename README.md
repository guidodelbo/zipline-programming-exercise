# Zipline Programming Exercise Solution

This is my solution for the "Grouping" programming exercise assignment.

The goal is to identify records in a CSV file that may represent the same person based on matching email addresses or phone numbers.

## Overview

The solution is implemented in Ruby and provides a robust way to group person records based on three matching types:
- `same_email`: Groups records with identical email addresses
- `same_phone`: Groups records with identical phone numbers
- `same_email_or_phone`: Groups records with identical email OR phone numbers

## Key Design Decisions

### 1. Data Validation Strategy
- **What to Validate**:
  - Required fields: FirstName, LastName, and at least one Email or Phone column
  - CSV structure (headers, row length)
  - File existence and non-emptiness
  - Matching type validity

- **What Not to Validate**:
  - Empty names
  - Email format
  - Phone number format
  - ZIP code format

**Reasoning**: The script's primary purpose is to associate records, not to validate data integrity. It assumes the input data has been pre-validated by the source system. Empty names are preserved to avoid data loss and they are considered as a match if the email or phone matches with another record, it could be useful for the user to identify records with no first or last name.

### 2. Matching Algorithm
**First Match Priority**: When a record has multiple potential matches (e.g., same email as record A and same phone as record B), it matches with the first one found.

- **Reasoning**: This approach was chosen for keeping the code simple and easy to understand. While more sophisticated matching strategies could be implemented (like scoring systems), the first-match approach provides a clear, deterministic result that's easy to understand and maintain.

**Transitive Matching**: Records are grouped transitively (if A matches B and B matches C, then A, B, and C are grouped together) for identifying all related records, even when they don't directly match.

The chosen approach prioritizes simplicity and reliability over complexity, while still providing accurate grouping results for the majority of use cases.

### 3. Implementation Approach
- **In-Memory Processing**: Uses arrays and hashes for data storage and matching
- **Simple Data Structures**:
  - Arrays for record storage
  - Hash maps for email/phone lookups

**Performance Considerations**:
- Current implementation scales linearly with input size
- Memory usage is proportional to the number of records
- For very large datasets (>1M records), I would consider:
  - Database-backed solution
  - Distributed processing

## Usage

```bash
ruby grouping.rb [options] <input_file> <matching_type>
```

Options:
- `-h, --help`: Show help message

Examples:
```bash
ruby grouping.rb input.csv same_email
ruby grouping.rb input.csv same_phone
ruby grouping.rb input.csv same_email_or_phone
```

## Testing

The solution includes a comprehensive test suite covering:
- Basic matching functionality
- Edge cases (empty files, missing fields)
- Multiple field scenarios
- Transitive matching
- Data validation
- Error handling

Run tests with:
```bash
ruby test_person_matcher.rb
```

## Performance Testing

Manual stress testing was performed using `input3.csv` (20,000 records):
- Processing time: ~0.2 seconds
- Memory usage: ~30MB
- Successfully identified and grouped matching records

## Future Improvements

1. **Matching Algorithm**:
   - Implement scoring system for multiple matches
   - Support custom matching rules

2. **Performance**:
   - Add database integration option for large files
   - Implement parallel processing

3. **Features**:
   - Add support for custom field matching
   - Add export options (JSON, XML)

## Code Organization

- `grouping.rb`: Main implementation
- `test_person_matcher.rb`: Test suite
- Clear separation of concerns:
  - Input validation
  - Record processing
  - Grouping logic
  - Output generation

## Dependencies

- Ruby standard library only
- No external dependencies
- Compatible with Ruby 2.0+

## Trade-offs Made

1. **Simplicity vs. Flexibility**:
   - Chose simple, clear implementation over complex features
   - Focused on core requirements first
   - Left room for future enhancements

2. **Validation vs. Tolerance**:
   - Minimal validation to handle various input formats
   - Preserved potentially invalid data for user review
   - Assumed pre-validated input data

3. **Performance vs. Memory**:
   - Used in-memory processing for simplicity
   - Acceptable for typical use cases
   - Scalable for moderate dataset sizes

## Conclusion

Thank you for this interesting assignment!

It was a fun challenge to work on, and I enjoyed the opportunity to design and implement a solution that balances simplicity with robustness. I focused on making the code clear and maintainable while ensuring it handles various edge cases through comprehensive testing.

I hope you find this solution valuable and I'm happy to discuss any of the design decisions or potential improvements in more detail!
