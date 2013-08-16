#encoding: utf-8
class CurrencyInWords::ThTexterizer

  def texterize context
    int_part, dec_part = context.number_parts
    connector          = context.options[:connector]
    int_unit_one       = context.options[:currency][:unit][:one]
    int_unit_many      = context.options[:currency][:unit][:many]
    dec_unit_one       = context.options[:currency][:decimal][:one]
    dec_unit_many      = context.options[:currency][:decimal][:many]
    @skip_and          = context.options[:skip_and]  || false
    @delimiter         = context.options[:delimiter] || false

    int_unit = int_part > 1 ? int_unit_many : int_unit_one
    dec_unit = dec_part > 1 ? dec_unit_many : dec_unit_one

    texterized_int_part = (texterize_by_group(int_part).compact << int_unit).flatten.join('')
    texterized_dec_part = (texterize_by_group(dec_part).compact << dec_unit).flatten.join('')

    if dec_part.zero?
      texterized_int_part << "ถ้วน"
    else
      texterized_int_part << connector << texterized_dec_part
    end
  end
  
  private
  
  # :nodoc: all
  A = %w(ศูนย์ หนึ่ง สอง สาม สี่ ห้า หก เจ็ด แปด เก้า)
  B = %w(สิบ สิบเอ็ด สิบสอง สิบสาม สิบสี่ สิบห้า สิบหก สิบเจ็ด สิบแปด สิบเก้า)
  C = [nil, nil, 'ยี่สิบ', 'สามสิบ', 'สี่สิบ', 'ห้าสิบ', 'หกสิบ', 'เจ็ดสิบ', 'แปดสิบ', 'เก้าสิบ']
  D = ['สิบ', 'ร้อย', 'พัน', 'หมื่น', 'แสน', 'ล้าน']

  def texterize_by_group number
    # satang
    return [under_100(number)] if number < 100

    # baht
    six_digit_numbers = []
    starter_number = number
    while starter_number != 0
      more_than_million_number, less_than_million_number = starter_number.divmod 1000000
      six_digit_numbers << less_than_million_number
      starter_number = more_than_million_number
    end

    words = []
    
    six_digit_numbers.each_with_index do |six_digit_number, index|
      words << under_1000000(six_digit_number).join("") + "ล้าน" * index
    end

    words.reverse!
    
    words
  end

  def under_1000000 number
    more_than_hundred_number, less_than_hundred_number = number.divmod 100

    words = []
    
    if more_than_hundred_number > 0
      more_than_hundred_digits = more_than_hundred_number.to_s.split('').map { |digit| digit.to_i }

      more_than_hundred_digits.each_with_index do |digit, index|
        if !digit.zero?
          words << A[digit] + D[more_than_hundred_digits.size - index]
        end
      end
    end
    if less_than_hundred_number > 0
      words << under_100(less_than_hundred_number)
    end

    words
  end

  def under_100 number
    case number
    when 0..9   then A[number]
    when 10..19 then B[number - 10]
    else
      q,r = number.divmod 10

      last_digit = ""
      unless r.zero?
        if r == 1
          last_digit = "เอ็ด"
        else
          last_digit = A[r]
        end
      end

      C[q] + (last_digit).to_s
    end
  end
end