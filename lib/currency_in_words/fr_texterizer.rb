#### 
# :nodoc: all
# This is the strategy class for French language
module CurrencyInWords
  class FrTexterizer
    
    def texterize context
      int_part, dec_part = context.number_parts
      connector          = context.options[:connector]
      int_unit_one       = context.options[:currency][:unit][:one]
      int_unit_many      = context.options[:currency][:unit][:many]
      int_unit_more      = context.options[:currency][:unit][:more]
      dec_unit_one       = context.options[:currency][:decimal][:one]
      dec_unit_many      = context.options[:currency][:decimal][:many]

      unless int_unit_many
        int_unit_many = int_unit_one+'s'
      end
      unless int_unit_more
        int_unit_more = if int_unit_many.start_with?("a","e","i","o","u")
                          "d'"+int_unit_many
                        else
                          "de "+int_unit_many
                        end
      end
      unless dec_unit_many
        dec_unit_many = dec_unit_one+'s'
      end

      int_unit = if int_part > 1
                   (int_part % 10**6).zero? ? int_unit_more : int_unit_many
                 else
                   int_unit_one
                 end
      dec_unit = dec_part > 1 ? dec_unit_many : dec_unit_one

      feminize = context.options[:currency][:unit][:feminine] || false
      texterized_int_part = (texterize_by_group(int_part, 0, feminize).compact << int_unit).flatten.join(' ')

      feminize = context.options[:currency][:decimal][:feminine] || false
      texterized_dec_part = (texterize_by_group(dec_part, 0, feminize).compact << dec_unit).flatten.join(' ')

      if dec_part.zero?
        texterized_int_part
      else
        texterized_int_part << connector << texterized_dec_part
      end
    end
   
    private

    # :nodoc: all
    A = %w(z&eacute;ro un deux trois quatre cinq six sept huit neuf)
    B = %w(dix onze douze treize quatorze quinze seize dix-sept dix-huit dix-neuf)
    C = [nil,nil,'vingt','trente','quarante','cinquante', 
         'soixante','soixante','quatre-vingt','quatre-vingt']
    D = [nil,'mille','million','milliard','billion','billiard','trillion','trilliard',
         'quadrillion','quadrilliard']

    def texterize_by_group number, group, feminine
      return [under_100(number, 0, feminine)] if number.zero?
      q,r = number.divmod 1000
      arr = texterize_by_group(q, group+1, feminine) if q > 0
      if r.zero?
        arr
      else
        arr = arr.to_a 
        arr << under_1000(r, group, feminine) 
        group.zero? ? arr : arr << (D[group] + ('s' if r > 1 && group != 1).to_s)
      end
    end
    
    def under_1000 number, group, feminine
      q,r = number.divmod 100
      arr = (q > 1 ? [A[q]] : []) << (r == 0 && q > 1 && group != 1 ? 'cents' : 'cent') if q > 0
      r.zero? ? arr : (r == 1 && q == 0 && group == 1 ? nil : arr.to_a << under_100(r, group, feminine))
    end

    def under_100 number, group, feminine
      feminine = (feminine and group.zero?)
      case number
      when 0..9   then A[number] + ('e' if feminine && number == 1).to_s
      when 10..19 then B[number - 10]
      else
        q,r = number.divmod 10
        case r
        when 1
          case q
          when 7 then C[q] + ('-et-' + B[r]).to_s
          when 8 then C[q] + ('-'    + A[r]).to_s + ('e' if feminine).to_s
          when 9 then C[q] + ('-'    + B[r]).to_s
          else        C[q] + ('-et-' + A[r]).to_s + ('e' if feminine).to_s
          end
        else
          if [7,9].include?(q)
            C[q] + ('-' + B[r]).to_s
          else
            C[q] + ('-' + A[r] if not r.zero?).to_s + ('s' if number == 80 && group != 1).to_s
          end
        end
      end
    end
  end
end