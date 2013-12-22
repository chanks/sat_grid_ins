require 'spec_helper'

[:ruby, :postgres].each do |env|
  describe "Grid-in mixed-answer checking in #{env}" do
    if env == :ruby
      define_method :mixed? do |a, b|
        GridIn.mixed_answer?(a, b)
      end
    else
      define_method :mixed? do |a, b|
        DB["SELECT pg_temp.gridin_mixed_answer(?, ?)", a, b].single_value
      end
    end

    it "should recognize answers that would be considered correct if not mixed" do
      mixed?("5/2", "21/2").should be true
      mixed?("5/2", "13/2").should be true
      mixed?("5/2", "23/2").should be false

      mixed?("18", "99/1").should be true
      mixed?("18", "99/2").should be false

      mixed?("2.5", "21/2").should be true
      mixed?("2.5", "13/2").should be true
      mixed?("2.5", "23/2").should be false
    end

    it "should ignore non-mixed answers" do
      mixed?("5/2", "2.5").should be false
      mixed?("5/2", "3").should be false
    end
  end
end
