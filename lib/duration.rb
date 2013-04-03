require 'support'

class Duration
  VERSION = '0.1.0'
  FIELDS = [:years, :months, :days, :hours, :minutes, :seconds]
  LETTERS = 'YMDHMS'
  OPTIONS = [:accuracy, :frac_digits, :frac_accuracy, :frac_sep, :alter, :alter_sep]

  def initialize(*args)
    options = {}
    input = nil

    if args.size > 0
      input = args.shift if args[0].is_a? String
      options = args.shift if args[0].is_a? Hash
    end

    options.symbolize!

    positive = options.delete :positive
    negative = options.delete :negative

    self.years = options.delete :years
    self.months = options.delete :months
    self.weeks = options.delete :weeks
    self.days = options.delete :days
    self.hours = options.delete :hours
    self.minutes = options.delete :minutes
    self.seconds = options.delete :seconds
    self.positive = positive.nil? ? (negative.nil? ? true : !negative) : positive

    @options = {
      accuracy: FIELDS.index(:seconds),
      frac_digits: 0,
      frac_accuracy: -1,
      frac_sep: '.',
      alter: false,
      alter_sep: false
    }.merge parse_options(options)

    if input.is_a?(String)
      if /^(?<sign>\+|\-)?P(?<years>\d\d\d\d)(?<sep1>-)?(?<months>\d\d)\k<sep1>?(?<days>\d\d)(?:T(?<hours>\d\d)(?<sep2>)?(?<minutes>\d\d)\k<sep2>(?<seconds>\d\d))?$/ =~ input
        self.alter = true
        self.alter_sep = sep1 == '-'
        self.years = years
        self.months = months
        self.days = days
        self.weeks = 0.0
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        self.positive = sign != '-'
      elsif /^(?<sign>\+|\-)?P(?:(?:(?<years>[\d.]+)Y)?(?:(?<months>[\d.]+)M)?(?:(?<days>[\d.]+)D)?(?:T(?:(?<hours>[\d.]+)H)?(?:(?<minutes>[\d.]+)M)?(?:(?<seconds>[\d.]+)S)?)?)|(?:(?<weeks>\d+)W)$/ =~ input.gsub(',', '.')
        self.alter = false
        self.years = years
        self.months = months
        self.days = days
        self.weeks = weeks
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        self.positive = sign != '-'
      end
    end
  end

  def positive=(value)
    raise ArgumentError.new "Positive should be a boolean" unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
    @positive = value
  end

  def negative=(value)
    raise ArgumentError.new "Negative should be a boolean" unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
    @positive = !value
  end

  def positive?
    @positive
  end

  def negative?
    !@positive
  end

  def accurate?
    @years == 0 && @months == 0 && @weeks == 0 && @days == 0
  end

  def nominal?
    !accurate?
  end

  def accuracy
    FIELDS[@options[:accuracy]]
  end

  def frac_accuracy
    return :undefined if @options[:frac_accuracy] < 0
    FIELDS[@options[:frac_accuracy]]
  end

  def iso8601(options = {})
    options = @options.merge parse_options(options.symbolize)

    if @weeks > 0
      "P#{@weeks.to_i}W"
    else
      # get array of values
      values = FIELDS.map do |field|
        value = instance_variable_get "@#{field}".to_sym
        value > 0 && options[:accuracy] >= FIELDS.index(field) ? value : 0
      end
      # trim all zero values from right
      while values[-1] == 0 do values.pop; end
      # return zero formatted value if all fields are 0
      return 'PT0S' if values.empty?
      # make an array of string representation
      i = -1
      last = values.size - 1
      values.map! do |value|
        i += 1
        if options[:alter]
          value.to_i
        else
          result = ''
          unless value == 0
            value = i < last ? value.to_i : value.round(options[:frac_accuracy] < 0 || options[:frac_accuracy] == i ? options[:frac_digits] : 0)
            result = "#{value.to_s}#{LETTERS[i]}"
            result.gsub! '.', options[:frac_sep] if options[:frac_sep] != '.'
          end
          result
        end
      end
      # get nominal and accuracy parts of value
      nom_parts = values[0..2] || []
      acc_parts = values[3..-1] || []
      # final format value in str
      str = self.negative? ? '-P' : 'P'
      if options[:alter]
        if nom_parts.count {|x| x > 0} > 0
          nom_parts = nom_parts.fill(0, nom_parts.size, 3 - nom_parts.size)
          raise RuntimeError.new "Number of days for alternative format should be equal or less then 30" unless nom_parts[2] <= 30
          raise RuntimeError.new "Number of months for alternative format should be equal or less then 12" unless nom_parts[1] <= 12
          raise RuntimeError.new "Number of years for alternative format should be equal or less then 9999" unless nom_parts[0] <= 9999
          str += sprintf(options[:alter_sep] ? '%04i-%02i-%02i' : '%04i%02i%02i', *nom_parts)
        end
        if acc_parts.count {|x| x > 0} > 0
          acc_parts = acc_parts.fill(0, acc_parts.size, 3 - acc_parts.size)
          raise RuntimeError.new "Number of hours for alternative format should be equal or less then 24" unless acc_parts[0] <= 24
          raise RuntimeError.new "Number of minutes for alternative format should be equal or less then 60" unless acc_parts[1] <= 60
          raise RuntimeError.new "Number of seconds for alternative format should be equal or less then 60" unless acc_parts[2] <= 60
          str += sprintf(options[:alter_sep] ? 'T%02i:%02i:%02i' : 'T%02i%02i%02i', *acc_parts)
        end
      else
        str += nom_parts.join if nom_parts.count {|x| !x.empty?} > 0
        str += 'T' + acc_parts.join if acc_parts.count {|x| !x.empty?} > 0
      end 
      str
    end
  end

  (FIELDS + [:weeks]).each do |getter|
    var_name = "@#{getter}".to_sym
    setter = "#{getter}=".to_sym
    define_method(getter) {instance_variable_get var_name} unless method_defined? getter
    define_method(setter) do |value|
      if value.nil?
        instance_variable_set var_name, 0
        return
      end
      unless value.is_a? Float
        raise ArgumentError.new "Value of class #{value.class.name} can not be converted to Float" unless value.respond_to? :to_f
        value = value.to_f
      end
      raise ArgumentError.new 'Value should be zero or positive' unless value >= 0
      instance_variable_set var_name, value
    end unless method_defined? setter
  end

  OPTIONS.each do |getter|
    setter = "#{getter}=".to_sym
    define_method(getter) {@options[getter]} unless method_defined? getter
    define_method(setter) do |value|
      parsed = send "parse_#{getter}".to_sym, value
      @options[getter] = parsed unless parsed.nil?
    end unless method_defined? setter
  end

  private
  def parse_accuracy(value)
    if value.is_a? Integer
      raise ArgumentError.new "Accuracy value must be in 0..#{FIELDS.size - 1}" unless value >= 0 && value < FIELDS.size
      return value
    elsif !value.is_a? Symbol
      raise ArgumentError.new "Can't convert value of class #{value.class.name} to symbol" unless value.respond_to? :to_sym
      value = value.to_sym
    end
    raise ArgumentError.new "Wrong accuracy value #{value}" unless FIELDS.include? value
    FIELDS.index value
  end

  def parse_frac_digits(value)
    unless value.is_a? Integer
      raise ArgumentError.new "Can't convert value of class #{value.class.name} to integer" unless value.respond_to :to_i
      value = value.to_i
    end
    raise ArgumentError.new "frac_digits should be zero or pozitive integer" unless value >= 0
    value
  end

  def parse_frac_accuracy(value)
    if value.is_a? Integer
      raise ArgumentError.new "Frac_accuracy value must be in -1..#{FIELDS.size - 1}" unless value >= -1 && value < FIELDS.size
      return value
    elsif !value.is_a? Symbol
      raise ArgumentError.new "Can't convert value of class #{value.class.name} to symbol" unless value.respond_to? :to_sym
      value = value.to_sym
    end
    raise ArgumentError.new "Wrong frac_accuracy value #{value}" unless FIELDS.include? value
    return -1 if [:no, :undefined].include? value
    FIELDS.index value
  end

  def parse_frac_sep(value)
    value.to_s[0]
  end

  def parse_alter(value)
    raise ArgumentError.new 'Alter options should be boolean' unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
    value
  end

  def parse_alter_sep(value)
    raise ArgumentError.new 'Alter_sep options should be boolean' unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
    value
  end

  def parse_options(options = {})
    options.each do |option, value|
      raise ArgumentError.new "Unsupported option #{option}" unless OPTIONS.include? option
      if value.nil?
        options.delete option
        next
      end
      name = "parse_#{option}".to_s
      if respond_to? name, true
        parsed = send name, value
        options[option] = parsed unless parsed.nil?
      end
    end
    options
  end

  def serialize_integer_value(value, letter)
    "#{value.to_i.to_s}#{letter}"
  end

  def serialize_float_value(value, index)
    "#{value.to_s}#{letter}"
  end    
end
