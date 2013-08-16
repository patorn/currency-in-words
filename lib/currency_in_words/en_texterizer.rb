#### 
# :nodoc: all
# This is the strategy class for English language
module CurrencyInWords
  class EnTexterizer

    def texterize context
      int_part, dec_part = context.number_parts
      connector          = context.options[:connector]
      int_unit_one       = context.options[:currency][:unit][:one]
      int_unit_many      = context.options[:currency][:unit][:many]
      dec_unit_one       = context.options[:currency][:decimal][:one]
      dec_unit_many      = context.options[:currency][:decimal][:many]
      @skip_and          = context.options[:skip_and]  || false
      @delimiter         = context.options[:delimiter] || false

      unless int_unit_many
        int_unit_many = int_unit_one+'s'
      end
      unless dec_unit_many
        dec_unit_many = dec_unit_one+'s'
      end

      int_unit = int_part > 1 ? int_unit_many : int_unit_one
      dec_unit = dec_part > 1 ? dec_unit_many : dec_unit_one

      texterized_int_part = (texterize_by_group(int_part).compact << int_unit).flatten.join(' ')
      texterized_dec_part = (texterize_by_group(dec_part).compact << dec_unit).flatten.join(' ')

      if dec_part.zero?
        texterized_int_part
      else
        texterized_int_part << connector << texterized_dec_part
      end
    end
    
    private
    
    # :nodoc: all
    A = %w(zero one two three four five six seven eight nine)
    B = %w(ten eleven twelve thirteen fourteen fifteen sixteen
           seventeen eighteen nineteen)
    C = [nil,nil,'twenty','thirty','forty','fifty','sixty','seventy',
         'eighty','ninety']
    D = [nil,'thousand','million','billion','trillion','quadrillion',
         'quintillion','sextillion','septillion','octillion']

    def texterize_by_group number, group=0
      return [under_100(number)] if number.zero?
      q,r = number.divmod 1000
      arr = texterize_by_group(q, group+1) if q > 0
      if r.zero?
        arr.last.chop! if group.zero? && @delimiter && arr.last.respond_to?('chop!')
        arr
      else
        arr = arr.to_a
        unless group.zero?
          arr << under_1000(r)
          arr << D[group] + (',' if @delimiter).to_s
        else
          arr.last.chop!  if @delimiter && r < 100 && arr.last.respond_to?('chop!')
          arr << 'and'    if !@skip_and && q > 0 && r < 100
          arr << under_1000(r)
        end
      end
    end
    
    def under_1000 number
      q,r = number.divmod 100
      arr = ([A[q]] << 'hundred' + (' and' unless @skip_and || r.zero?).to_s) if q > 0
      r.zero? ? arr : arr.to_a << under_100(r)
    end

    def under_100 number
      case number
      when 0..9   then A[number]
      when 10..19 then B[number - 10]
      else
        q,r = number.divmod 10
        C[q] + ('-' + A[r] unless r.zero?).to_s
      end
    end
  end
end