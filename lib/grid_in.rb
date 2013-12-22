class GridIn < String
  RANGE_REGEX    = /\A([\(\[])(.*),(.*)([\)\]])\z/
  VALIDITY_REGEX = /\A[1-9\. ][0-9\.\/ ]{2}[0-9\. ]\z/

  class << self
    def correct?(key, value)
      new(key) == new(value)
    end

    # Tweaks the given input text into a usable form. Given "[30,40]" will
    # also return "30", as a general utility for use in testing.
    def format(input)
      input ||= ''
      input = input.split(';').first || ''
      input = input.split(',').first || ''
      input = input.gsub(/[^\d\ \.\/]/, '')[0..3]
      input = ' ' + input until input.length == 4
      input
    end

    # Need to be able to accept the correct answer being rounded off to three
    # digits or truncated to three digits.
    def close_enough?(key, response)
      decimal_places = case response.to_f
                         when  0.0...1.0   then 3
                         when  1.0...10.0  then 2
                         when 10.0...100.0 then 1
                         else                   3
                       end

      response = response.to_f.round(decimal_places)

      case key
      when Float
        response == key
      when Rational
        response == key.to_f.round(decimal_places) ||                                  # Rounded.
        response == Integer(key.to_f * 10**decimal_places) / Float(10**decimal_places) # Truncated.
      else
        raise "Should not get here! #{key.inspect}"
      end
    end

    # If the answer was 5/2 and the user gave 21/2, they may not know that
    # they can't give mixed numbers as answers, so we have to remind them.
    def mixed_answer?(key, answer)
      return false unless answer =~ /\A(\d)(\d\/\d)\z/
      correct? key, (new($2).to_value + $1.to_i).to_s
    end
  end

  def valid_response?
    !!match(VALIDITY_REGEX)
  end

  def ==(other)
    return super unless other.is_a? GridIn
    return split(';').any? { |e| e == other } if match /;/
    return false if (this = to_value).nil? || (that = other.to_value).nil?

    case this
    when Float
      this == that
    when Rational
      self.class.close_enough?(this, that)
    when Range
      this.cover?(that)
    else
      raise "Should not reach me! #{this.inspect}"
    end
  end

  # Returns a range, rational or float that's representative of the GridIn's
  # content, or nil if it's just gibberish.
  def to_value
    value = case self
            when RANGE_REGEX
              if (a, b = [$2, $3].map{|s| self.class.new(s).to_value}).any? &:nil?
                nil
              else
                Range.new a: a, b: b, include_a: $1 == '[', include_b: $4 == ']'
              end
            when /\//
              one, two = split('/').map(&:to_value)

              if two.nil? || two.zero?
                nil
              else
                (one / two).rationalize
              end
            else
              to_f
            end

    # Crappy input that shouldn't equal anything will wind up being zero. If
    # the value is zero, but the numeral "0" doesn't appear in the grid-in,
    # let's just call it nothing.
    value unless value.respond_to?(:zero?) && value.zero? && self !~ /0/
  end

  def split(delimiter)
    super.map { |s| self.class.new(s) }
  end

  def to_display
    case self
    when /;/
      array = split(";").map(&:to_display)

      case array.length
      when 1 then array.first
      when 2 then array.join(' or ')
      else
        last = array.pop
        array.join(', ') << ", or #{last}"
      end
    when RANGE_REGEX
      "#{$2} #{inequality_for($1)} x #{inequality_for($4)} #{$3}"
    else
      to_s
    end
  end

  private

  def inequality_for(s)
    case s
      when /[\[\]]/ then "≤"
      when /[\(\)]/ then "<"
    end
  end

  class Range
    attr_reader :a, :b

    def initialize(a: raise, b: raise, **attrs)
      @a, @b, @attrs = a, b, attrs
    end

    def cover?(thing)
      if @attrs[:include_a] && GridIn.close_enough?(a, thing)
        true
      elsif @attrs[:include_b] && GridIn.close_enough?(b, thing)
        true
      else
        @a != thing && @b != thing && (@a..@b).cover?(thing)
      end
    end
  end
end
