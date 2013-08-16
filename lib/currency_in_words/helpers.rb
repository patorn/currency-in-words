# encoding: utf-8
module CurrencyInWords
  ActionView::Helpers::NumberHelper.class_eval do

    DEFAULT_CURRENCY_IN_WORDS_VALUES = {:currencies=>{:default=>{:unit=>{:one=>'dollar',:many=>'dollars'},
                                        :decimal=>{:one=>'cent',:many=>'cents'}}},
                                        :connector=>', ',:format=>'%n',:negative_format=>'minus %n'}

    # Formats a +number+ into a currency string (e.g., 'one hundred dollars'). You can customize the 
    # format in the +options+ hash.
    #
    # === Options for all locales
    # * <tt>:locale</tt> - Sets the locale to be used for formatting (defaults to current locale).
    # * <tt>:currency</tt> - Sets the denomination of the currency (defaults to :default currency for the locale or "dollar" if not set).
    # * <tt>:connector</tt> - Sets the connector between integer part and decimal part of the currency (defaults to ", ").
    # * <tt>:format</tt> - Sets the format for non-negative numbers (defaults to "%n").
    # Field is <tt>%n</tt> for the currency amount in words.
    # * <tt>:negative_format</tt> - Sets the format for negative numbers (defaults to prepending "minus" to the number in words).
    # Field is <tt>%n</tt> for the currency amount in words (same as format).
    #
    # ==== Examples
    # [<tt>number_to_currency_in_words(123456.50)</tt>] 
    #   \=> one hundred and twenty-three thousand four hundred and fifty-six dollars, fifty cents
    # [<tt>number_to_currency_in_words(123456.50, :connector => ' and ')</tt>]
    #   \=> one hundred and twenty-three thousand four hundred and fifty-six dollars and fifty cents
    # [<tt>number_to_currency_in_words(123456.50, :locale => :fr, :connector => ' et ')</tt>] 
    #   \=> cent vingt-trois mille quatre cent cinquante-six dollars et cinquante cents
    # [<tt>number_to_currency_in_words(80300.80, :locale => :fr, :currency => :euro, :connector => ' et ')</tt>]
    #   \=> quatre-vingt mille trois cents euros et quatre-vingts centimes
    #
    # === Options only available for :en locale
    # * <tt>:delimiter</tt> - Sets the thousands delimiter (defaults to false).
    # * <tt>:skip_and</tt> - Skips the 'and' part in number - US (defaults to false).
    #
    # ==== Examples
    # [<tt>number_to_currency_in_words(201201201.201, :delimiter => true)</tt>] 
    #   \=> two hundred and one million, two hundred and one thousand, two hundred and one dollars, twenty cents
    # [<tt>number_to_currency_in_words(201201201.201, :delimiter => true, :skip_and => true)</tt>]
    #   \=> two hundred one million, two hundred one thousand, two hundred one dollars, twenty cents
    def number_to_currency_in_words number, options = {}

      options.symbolize_keys!

      currency_in_words = I18n.translate(:'number.currency_in_words', :locale => options[:locale], :default => {})

      defaults = DEFAULT_CURRENCY_IN_WORDS_VALUES.merge(currency_in_words)

      options  = defaults.merge!(options) 

      unless options[:currencies].has_key?(:default)
        options[:currencies].merge!(DEFAULT_CURRENCY_IN_WORDS_VALUES[:currencies])
      end

      format     = options.delete(:format)
      currency   = options.delete(:currency)
      currencies = options.delete(:currencies)
      options[:currency]  = currency && currencies.has_key?(currency) ? currencies[currency] : currencies[:default]
      options[:locale]  ||= I18n.default_locale

      if number.to_f < 0
        format = options.delete(:negative_format)
        number = number.respond_to?("abs") ? number.abs : number.sub(/^-/, '')
      end

      options_precision = {
        :precision => 2,
        :delimiter => '',
        :significant => false,
        :strip_insignificant_zeros => false,
        :separator => '.',
        :raise => true
      }

      begin
        rounded_number = number_with_precision(number, options_precision)
      rescue ActionView::Helpers::NumberHelper::InvalidNumberError => e
        if options[:raise]
          raise
        else
          rounded_number = format.gsub(/%n/, e.number)
          return e.number.to_s.html_safe? ? rounded_number.html_safe : rounded_number
        end
      end

      begin
        klass = "CurrencyInWords::#{options[:locale].to_s.capitalize}Texterizer".constantize
      rescue NameError
        if options[:raise]
          raise NameError, "Implement a class #{options[:locale].to_s.capitalize}Texterizer to support this locale, please."
        else
          klass = EnTexterizer
        end
      end

      number_parts = rounded_number.split(options_precision[:separator]).map(&:to_i)
      texterizer = CurrencyInWords::Texterizer.new(klass.new, number_parts, options)
      texterized_number = texterizer.texterize
      format.gsub(/%n/, texterized_number).html_safe
    end
  end
end