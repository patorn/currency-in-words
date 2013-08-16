#### 
# :nodoc: all
# This is the context class for texterizers
module CurrencyInWords
  class Texterizer
    attr_reader :number_parts, :options, :texterizer

    def initialize texterizer, splitted_number, options = {}
      @texterizer   = texterizer
      @number_parts = splitted_number
      @options      = options
    end

    def texterize
      if @texterizer.respond_to?('texterize')
        texterized_number = @texterizer.texterize self
        if texterized_number.is_a?(String)
          return texterized_number
        else
          raise TypeError, "a texterizer must return a String" if @options[:raise]
        end
      else
        raise NoMethodError, "a texterizer must provide a 'texterize' method" if @options[:raise]
      end
      # Fallback on EnTexterizer
      unless @texterizer.instance_of?(EnTexterizer)
        @texterizer = EnTexterizer.new
        self.texterize
      else
        raise RuntimeError, "you should use the option ':raise => true' to see what goes wrong"
      end
    end
  end
end