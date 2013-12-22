require 'spec_helper'

[:ruby, :postgres].each do |env|
  describe "Grid-in equivalence in #{env}" do
    if env == :ruby
      define_method :gridin_equivalence do |a, b|
        GridIn.correct?(a, b)
      end
    else
      define_method :gridin_equivalence do |a, b|
        DB["SELECT pg_temp.gridin_equivalent(?, ?)", a, b].single_value
      end
    end

    it "should compare integers to each other" do
      gridin_equivalence("   0", "   0").should be true
      gridin_equivalence("   0", "0   ").should be true
      gridin_equivalence("   0", "00  ").should be true

      gridin_equivalence("3356", "3355").should be false
      gridin_equivalence("3356", "3356").should be true
      gridin_equivalence("3356", "3357").should be false
    end

    it "should ignore whitespace when comparing integers" do
      gridin_equivalence("335 ", " 335").should be true
      gridin_equivalence("335 ", "335 ").should be true
      gridin_equivalence(" 335", " 335").should be true
      gridin_equivalence("3   ", "   3").should be true
      gridin_equivalence("3   ", "3   ").should be true
      gridin_equivalence("   3", "   3").should be true

      gridin_equivalence("335 ", " 336").should be false
      gridin_equivalence("335 ", "336 ").should be false
      gridin_equivalence("3   ", "   2").should be false

      gridin_equivalence("335 ", "3356").should be false
    end

    it "should ignore leading zeroes when comparing integers" do
      gridin_equivalence("3   ", "0003").should be true
      gridin_equivalence("3   ", "  03").should be true
      gridin_equivalence("3   ", "   3").should be true
      gridin_equivalence("0003", "3   ").should be true

      gridin_equivalence("4   ", "0003").should be false
      gridin_equivalence("4   ", "  03").should be false
      gridin_equivalence("4   ", "   3").should be false
      gridin_equivalence("0004", "   3").should be false
    end

    it "should require an exact numeric match when the receiver is a float" do
      gridin_equivalence("0.20", "0.20").should be true
      gridin_equivalence("0.02", "0.02").should be true
      gridin_equivalence("0.2 ", "0.25").should be false
      gridin_equivalence("0.2 ", ".199").should be false
      gridin_equivalence("0.2 ", ".201").should be false

      gridin_equivalence("0.66", "0.60").should be false
      gridin_equivalence("0.66", "0.65").should be false
      gridin_equivalence("0.66", "0.66").should be true
      gridin_equivalence("0.66", "0.67").should be false

      gridin_equivalence(".666", ".66 ").should be false
      gridin_equivalence(".666", ".665").should be false
      gridin_equivalence(".666", ".666").should be true
      gridin_equivalence(".666", ".667").should be false
      gridin_equivalence(".666", ".67 ").should be false
    end

    it "should ignore whitespace when comparing decimals" do
      gridin_equivalence("0.2 ", "0.2 ").should be true
      gridin_equivalence("0.2 ", " 0.2").should be true
      gridin_equivalence("0.2 ", "0.2 ").should be true
      gridin_equivalence("0.2 ", " 0.2").should be true
      gridin_equivalence("0.20", " 0.2").should be true

      gridin_equivalence("0.2 ", " 0.3").should be false
      gridin_equivalence("0.20", " 0.3").should be false
      gridin_equivalence("0.2 ", "0.3 ").should be false
      gridin_equivalence("0.66", "0.6 ").should be false
    end

    it "should ignore leading zeroes when comparing decimals" do
      gridin_equivalence("0.60", ".600").should be true
      gridin_equivalence("0.60", "00.6").should be true
      gridin_equivalence("0.60", "  .6").should be true
      gridin_equivalence(".600", "  .6").should be true

      gridin_equivalence("0.66", "  .6").should be false
      gridin_equivalence("0.66", " .66").should be true
      gridin_equivalence("0.66", ".666").should be false

      gridin_equivalence(".666", "0.66").should be false
      gridin_equivalence(".666", ".665").should be false
      gridin_equivalence(".666", ".666").should be true
      gridin_equivalence(".666", ".667").should be false
    end

    it "should compare rationals to each other" do
      gridin_equivalence("10/3", "10/3").should be true
      gridin_equivalence("10/1", "20/2").should be true
      gridin_equivalence("18/4", "9/2 ").should be true

      gridin_equivalence("10/3", "10/4").should be false
      gridin_equivalence("10/3", " 1/3").should be false
    end

    it "should ignore whitespace when comparing rationals" do
      gridin_equivalence("1/3 ", " 1/3").should be true
      gridin_equivalence("1/3 ", "1/3 ").should be true
      gridin_equivalence("1/3 ", "1/4 ").should be false
      gridin_equivalence("1/3 ", " 1/4").should be false
    end

    it "should ignore leading zeroes when comparing rationals" do
      gridin_equivalence("1/3 ", "01/3").should be true
      gridin_equivalence("01/3", " 1/3").should be true
      gridin_equivalence("1/3 ", "01/4").should be false
    end

    it "should compare integers and decimals to one another" do
      gridin_equivalence("   0", " 0.0").should be true
      gridin_equivalence("   0", "0.00").should be true
      gridin_equivalence("   0", "00.0").should be true
      gridin_equivalence("  13", "13.0").should be true
      gridin_equivalence("   1", " 1.0").should be true
      gridin_equivalence("0013", "13.0").should be true
      gridin_equivalence("0001", "01.0").should be true

      gridin_equivalence("6   ", ".599").should be false
      gridin_equivalence("6   ", ".600").should be false
      gridin_equivalence("6   ", ".601").should be false

      # Not sure about this one, but ok, for now.
      gridin_equivalence("13.0", "13  ").should be true

      gridin_equivalence("  13", "0.13").should be false
      gridin_equivalence("  13", ".130").should be false
      gridin_equivalence("  13", "1.30").should be false
      gridin_equivalence("  13", "1.3 ").should be false
      gridin_equivalence("  13", " 1.3").should be false
    end

    it "should compare rationals and integers to one another" do
      gridin_equivalence("   0", "0/13").should be true
      gridin_equivalence("  17", "17/1").should be true
      gridin_equivalence("   1", " 1/1").should be true

      gridin_equivalence("   3", " 3/1").should be true
      gridin_equivalence(" 3/1", "   3").should be true
      gridin_equivalence("   2", " 4/2").should be true
      gridin_equivalence(" 4/2", "   2").should be true

      gridin_equivalence("30  ", "30/1").should be true
      gridin_equivalence("11  ", "99/9").should be true
      gridin_equivalence("99/9", "11  ").should be true
      gridin_equivalence("33  ", "99/3").should be true

      gridin_equivalence(" 5/2", "   2").should be false
      gridin_equivalence(" 5/2", "   3").should be false
      gridin_equivalence("30/4", "   3").should be false
      gridin_equivalence("19/9", "   2").should be false
      gridin_equivalence("19/9", "   3").should be false
    end

    it "should compare rationals and decimals to one another" do
      gridin_equivalence("1/25", "0.04").should be true
      gridin_equivalence("1/25", ".04 ").should be true
      gridin_equivalence(" 1/2", "0.50").should be true
      gridin_equivalence(" 1/8", ".125").should be true
      gridin_equivalence(" 7/4", "1.75").should be true
      gridin_equivalence(" 2/5", "0.40").should be true
      gridin_equivalence(" 2/5", ".400").should be true
      gridin_equivalence(" 2/5", "  .4").should be true

      gridin_equivalence("19/9", "2.10").should be false
      gridin_equivalence("19/9", "2.1 ").should be false
      gridin_equivalence("19/9", "2.11").should be true
      gridin_equivalence("19/9", "2.12").should be false
      gridin_equivalence("19/9", "2.2 ").should be false

      gridin_equivalence(" 2/7", ".284").should be false
      gridin_equivalence(" 2/7", ".285").should be true
      gridin_equivalence(" 2/7", ".286").should be true
      gridin_equivalence(" 2/7", ".287").should be false

      gridin_equivalence(" 8/3", "2.65").should be false
      gridin_equivalence(" 8/3", "2.66").should be true
      gridin_equivalence(" 8/3", "2.67").should be true
      gridin_equivalence(" 8/3", "2.68").should be false

      gridin_equivalence(" 3/7", ".427").should be false
      gridin_equivalence(" 3/7", ".428").should be true
      gridin_equivalence(" 3/7", ".429").should be true
      gridin_equivalence(" 3/7", ".430").should be false

      gridin_equivalence("1/15", ".065").should be false
      gridin_equivalence("1/15", ".066").should be true
      gridin_equivalence("1/15", ".067").should be true
      gridin_equivalence("1/15", ".068").should be false

      gridin_equivalence("7/15", ".465").should be false
      gridin_equivalence("7/15", ".466").should be true
      gridin_equivalence("7/15", ".467").should be true
      gridin_equivalence("7/15", ".468").should be false

      gridin_equivalence("5/11", ".453").should be false
      gridin_equivalence("5/11", ".454").should be true
      gridin_equivalence("5/11", ".455").should be true
      gridin_equivalence("5/11", ".456").should be false

      gridin_equivalence("5/18", ".276").should be false
      gridin_equivalence("5/18", ".277").should be true
      gridin_equivalence("5/18", ".278").should be true
      gridin_equivalence("5/18", ".279").should be false

      gridin_equivalence("10/7", "1.41").should be false
      gridin_equivalence("10/7", "1.42").should be true
      gridin_equivalence("10/7", "1.43").should be true
      gridin_equivalence("10/7", "1.44").should be false

      gridin_equivalence(" 1/9", ".110").should be false
      gridin_equivalence(" 1/9", ".111").should be true
      gridin_equivalence(" 1/9", ".112").should be false

      gridin_equivalence("10/3", "3.32").should be false
      gridin_equivalence("10/3", "3.33").should be true
      gridin_equivalence("10/3", "3.34").should be false

      gridin_equivalence("8/7", "1.13").should be false
      gridin_equivalence("8/7", "1.14").should be true
      gridin_equivalence("8/7", "1.15").should be false

      gridin_equivalence(" 4/9", ".443").should be false
      gridin_equivalence(" 4/9", ".444").should be true
      gridin_equivalence(" 4/9", ".445").should be false

      gridin_equivalence("17/2", "8.5" ).should be true
      gridin_equivalence("6/25", ".24" ).should be true
      gridin_equivalence("21/5", "4.2" ).should be true
      gridin_equivalence("93/2", "46.5").should be true
      gridin_equivalence("3/50", ".06").should be true
      gridin_equivalence("9/2",  "4.5" ).should be true
      gridin_equivalence("3/8",  ".375").should be true

      gridin_equivalence("30/4", "7.5 ").should be true
      gridin_equivalence("30/4", "7.50").should be true
      gridin_equivalence("30/4", " 7.5").should be true
      gridin_equivalence("30/4", "07.5").should be true

      # People might enter 21/2, trying to say 2 and a half.
      gridin_equivalence("21/2", "10.5").should be true
      gridin_equivalence("21/2", "2.5 ").should be false

      gridin_equivalence("1/5 ", ".201").should be false
      gridin_equivalence("1/5 ", ".200").should be true
      gridin_equivalence("1/5 ", ".199").should be false
      gridin_equivalence("6/5 ", "1.2 ").should be true

      gridin_equivalence(" 1/3", ".3  ").should be false
      gridin_equivalence(" 1/3", ".33 ").should be false
      gridin_equivalence(" 1/3", ".332").should be false
      gridin_equivalence(" 1/3", ".333").should be true
      gridin_equivalence(" 1/3", ".334").should be false
      gridin_equivalence(" 1/3", ".34 ").should be false

      gridin_equivalence(" 1/6", ".165").should be false
      gridin_equivalence(" 1/6", ".166").should be true
      gridin_equivalence(" 1/6", ".167").should be true
      gridin_equivalence(" 1/6", ".168").should be false
      gridin_equivalence(" 1/6", ".16 ").should be false
      gridin_equivalence(" 1/6", ".160").should be false
      gridin_equivalence(" 1/6", ".17 ").should be false
      gridin_equivalence(" 1/6", ".170").should be false

      gridin_equivalence(" 2/3", ".6  ").should be false
      gridin_equivalence(" 2/3", ".66 ").should be false
      gridin_equivalence(" 2/3", ".665").should be false
      gridin_equivalence(" 2/3", ".666").should be true
      gridin_equivalence(" 2/3", ".667").should be true
      gridin_equivalence(" 2/3", ".668").should be false
      gridin_equivalence(" 2/3", ".67 ").should be false
      gridin_equivalence(" 2/3", "0.66").should be false
      gridin_equivalence(" 2/3", "0.67").should be false

      gridin_equivalence("4/3", "1.32").should be false
      gridin_equivalence("4/3", "1.33").should be true
      gridin_equivalence("4/3", "1.34").should be false

      gridin_equivalence("5/3", "1.65").should be false
      gridin_equivalence("5/3", "1.66").should be true
      gridin_equivalence("5/3", "1.67").should be true
      gridin_equivalence("5/3", "1.68").should be false

      gridin_equivalence("27/8", "3.36").should be false
      gridin_equivalence("27/8", "3.37").should be true
      gridin_equivalence("27/8", "3.38").should be true
      gridin_equivalence("27/8", "3.39").should be false

      gridin_equivalence("80/3", "26.6").should be true
      gridin_equivalence("80/3", "26.7").should be true
      gridin_equivalence("8/3", "2.66").should be true
      gridin_equivalence("8/3", "2.67").should be true

      gridin_equivalence("70/3", "23.2").should be false
      gridin_equivalence("70/3", "23.3").should be true
      gridin_equivalence("70/3", "23.4").should be false

      gridin_equivalence(" 5/3", "1.65").should be false
      gridin_equivalence(" 5/3", "1.66").should be true
      gridin_equivalence(" 5/3", "1.67").should be true
      gridin_equivalence(" 5/3", "1.68").should be false

      gridin_equivalence(".666", "2/3").should be false
      gridin_equivalence(".667", "2/3").should be false
    end

    it "should handle decimals inside of rationals correctly" do
      gridin_equivalence("20/3", "2/.3").should be true
      gridin_equivalence("20/3", "4/.6").should be true

      gridin_equivalence("1/15", ".2/3").should be true
      gridin_equivalence("1/15", ".4/6").should be true

      gridin_equivalence("2/.3", "6.66").should be true
      gridin_equivalence("2/.3", "6.67").should be true

      gridin_equivalence("8   ", "4/.5").should be true
      gridin_equivalence("8.0 ", "4/.5").should be true
      gridin_equivalence("8/1 ", "4/.5").should be true
    end

    it "should not consider anything equal when encountering crazy input" do
      gridin_equivalence("   0", "....").should be false
      gridin_equivalence("   0", " // ").should be false
      gridin_equivalence("   0", "    ").should be false
      gridin_equivalence("   0", ".//.").should be false

      gridin_equivalence("   0", " 1/0").should be false
      gridin_equivalence("   0", ".6/0").should be false

      gridin_equivalence("0-1",       ".//.").should be false
      gridin_equivalence("[0.1,1.4]", ".//.").should be false
      gridin_equivalence("1/3-1/2",   ".//.").should be false

      gridin_equivalence("....", "....").should be false
      gridin_equivalence(" // ", " // ").should be false
      gridin_equivalence("    ", "    ").should be false
      gridin_equivalence(".//.", ".//.").should be false
    end

    it "should handle ranges correctly" do
      # Values in the middle work?
      gridin_equivalence("[1/3,2/3]", "2/5 ").should be true
      gridin_equivalence("[1/3,2/3]", "1/2 ").should be true
      gridin_equivalence("[1/3,2/3]", "3/5 ").should be true
      gridin_equivalence("(1/3,2/3]", "2/5 ").should be true
      gridin_equivalence("[1/3,2/3)", "1/2 ").should be true
      gridin_equivalence("(1/3,2/3)", "3/5 ").should be true

      # Either end of the range works?
      gridin_equivalence("[1/3,2/3]", "1/3 ").should be true
      gridin_equivalence("[1/3,2/3]", "2/6 ").should be true
      gridin_equivalence("[1/3,2/3]", "2/3 ").should be true
      gridin_equivalence("[1/3,2/3]", "4/6 ").should be true

      # Either end of the range doesn't work for exclusive ranges?
      gridin_equivalence("(1/3,2/3]", "1/3 ").should be false
      gridin_equivalence("(1/3,2/3)", "1/3 ").should be false
      gridin_equivalence("(1/3,2/3]", "2/6 ").should be false
      gridin_equivalence("(1/3,2/3)", "2/6 ").should be false
      gridin_equivalence("[1/3,2/3)", "2/3 ").should be false
      gridin_equivalence("(1/3,2/3)", "2/3 ").should be false
      gridin_equivalence("[1/3,2/3)", "4/6 ").should be false
      gridin_equivalence("(1/3,2/3)", "4/6 ").should be false

      # Behavior you may not expect for edge cases.
      gridin_equivalence("(1/3,2/3]", ".666").should be true
      gridin_equivalence("(1/3,2/3)", ".666").should be true
      gridin_equivalence("(1/3,2/3]", ".667").should be true
      gridin_equivalence("(1/3,2/3)", ".667").should be false
      gridin_equivalence("[2/3,3/4)", ".666").should be true
      gridin_equivalence("(2/3,3/4)", ".666").should be false
      gridin_equivalence("[2/3,3/4)", ".667").should be true
      gridin_equivalence("(2/3,3/4)", ".667").should be true

      gridin_equivalence("(70/3,71/3)", "23.2").should be false
      gridin_equivalence("(70/3,71/3)", "23.3").should be false
      gridin_equivalence("(70/3,71/3)", "23.4").should be true
      gridin_equivalence("[70/3,71/3)", "23.2").should be false
      gridin_equivalence("[70/3,71/3)", "23.3").should be true
      gridin_equivalence("[70/3,71/3)", "23.4").should be true

      gridin_equivalence("(4/3,5/3)", "1.65").should be true
      gridin_equivalence("(4/3,5/3)", "1.66").should be true
      gridin_equivalence("(4/3,5/3)", "1.67").should be false
      gridin_equivalence("(4/3,5/3)", "1.68").should be false
      gridin_equivalence("(4/3,5/3]", "1.65").should be true
      gridin_equivalence("(4/3,5/3]", "1.66").should be true
      gridin_equivalence("(4/3,5/3]", "1.67").should be true
      gridin_equivalence("(4/3,5/3]", "1.68").should be false

      # Values outside the range are rejected?
      gridin_equivalence("[1/3,2/3]", "1/4 ").should be false
      gridin_equivalence("[1/3,2/3]", "3/3 ").should be false
      gridin_equivalence("[1/3,2/3]", "1   ").should be false

      # Other types work?
      gridin_equivalence("[1/3,2/3]", ".333").should be true
      gridin_equivalence("[1/3,2/3]", ".444").should be true
      gridin_equivalence("[1/3,2/3]", ".500").should be true
      gridin_equivalence("[1/3,2/3]", ".666").should be true
      gridin_equivalence("[1/3,2/3]", ".667").should be true

      # Integers?
      gridin_equivalence("[9,12]", "9   ").should be true
      gridin_equivalence("[9,12]", "10  ").should be true
      gridin_equivalence("[9,12]", "12  ").should be true
      gridin_equivalence("[9,12]", "10.0").should be true
      gridin_equivalence("[9,12]", "21/2").should be true
      gridin_equivalence("[9,12]", "8   ").should be false
      gridin_equivalence("[9,12]", "8.0 ").should be false
      gridin_equivalence("[9,12]", "16/2").should be false

      # Decimals?
      gridin_equivalence("[8.5,9.5]", "8.50").should be true
      gridin_equivalence("[8.5,9.5]", "8.5 ").should be true
      gridin_equivalence("[8.5,9.5]", "9.0 ").should be true
      gridin_equivalence("[8.5,9.5]", "9.5 ").should be true
      gridin_equivalence("[8.5,9.5]", "9.50").should be true
      gridin_equivalence("[8.5,9.5]", "17/2").should be true
      gridin_equivalence("[8.5,9.5]", "27/3").should be true
      gridin_equivalence("[8.5,9.5]", "19/2").should be true
      gridin_equivalence("[8.5,9.5]", "9   ").should be true
      gridin_equivalence("[8.5,9.5]", "8   ").should be false
      gridin_equivalence("[8.5,9.5]", "10  ").should be false
      gridin_equivalence("[8.5,9.5]", "8.49").should be false
      gridin_equivalence("[8.5,9.5]", "9.51").should be false
      gridin_equivalence("[8.5,9.5]", "24/3").should be false
    end

    it "should handle semicolon-separated values correctly" do
      # Integers?
      gridin_equivalence("6;9;12", "5").should be false
      gridin_equivalence("6;9;12", "6").should be true
      gridin_equivalence("6;9;12", "7").should be false
      gridin_equivalence("6;9;12", "9").should be true
      gridin_equivalence("6;9;12", "11").should be false
      gridin_equivalence("6;9;12", "12").should be true
      gridin_equivalence("6;9;12", "13").should be false

      gridin_equivalence("6;9;12", "5.0").should be false
      gridin_equivalence("6;9;12", "6.0").should be true
      gridin_equivalence("6;9;12", "7.0").should be false
      gridin_equivalence("6;9;12", "9.0").should be true
      gridin_equivalence("6;9;12", "11.0").should be false
      gridin_equivalence("6;9;12", "12.0").should be true
      gridin_equivalence("6;9;12", "13.0").should be false

      gridin_equivalence("6;9;12", "5/1").should be false
      gridin_equivalence("6;9;12", "12/2").should be true
      gridin_equivalence("6;9;12", "7/2").should be false
      gridin_equivalence("6;9;12", "9/1").should be true
      gridin_equivalence("6;9;12", "11/5").should be false
      gridin_equivalence("6;9;12", "36/3").should be true
      gridin_equivalence("6;9;12", "13/2").should be false

      # Fractions?
      gridin_equivalence("1/4;1/2;3/4", "1/5").should be false
      gridin_equivalence("1/4;1/2;3/4", "1/4").should be true
      gridin_equivalence("1/4;1/2;3/4", "1/3").should be false
      gridin_equivalence("1/4;1/2;3/4", "1/2").should be true
      gridin_equivalence("1/4;1/2;3/4", "3/5").should be false
      gridin_equivalence("1/4;1/2;3/4", "3/4").should be true
      gridin_equivalence("1/4;1/2;3/4", "4/5").should be false

      gridin_equivalence("1/4;1/2;3/4", "0.25").should be true
      gridin_equivalence("1/4;1/2;3/4", "0.26").should be false
      gridin_equivalence("1/4;1/2;3/4", "0.5").should be true
      gridin_equivalence("1/4;1/2;3/4", "0.74").should be false
      gridin_equivalence("1/4;1/2;3/4", "0.75").should be true

      gridin_equivalence("1/3;2/3", ".332").should be false
      gridin_equivalence("1/3;2/3", ".333").should be true
      gridin_equivalence("1/3;2/3", ".334").should be false
      gridin_equivalence("1/3;2/3", ".665").should be false
      gridin_equivalence("1/3;2/3", ".666").should be true
      gridin_equivalence("1/3;2/3", ".667").should be true
      gridin_equivalence("1/3;2/3", ".668").should be false

      # Decimals?
      gridin_equivalence(".2;.4", ".199").should be false
      gridin_equivalence(".2;.4", ".2").should be true
      gridin_equivalence(".2;.4", ".200").should be true
      gridin_equivalence(".2;.4", ".3").should be false
      gridin_equivalence(".2;.4", ".4").should be true
      gridin_equivalence(".2;.4", ".40").should be true
      gridin_equivalence(".2;.4", ".41").should be false

      gridin_equivalence(".2;.4", "1/5").should be true
      gridin_equivalence(".2;.4", "2/5").should be true
      gridin_equivalence(".2;.4", "3/5").should be false

      # Ranges?
      gridin_equivalence("[3,4];[5,6]", "2").should be false
      gridin_equivalence("[3,4];[5,6]", "3").should be true
      gridin_equivalence("[3,4];[5,6]", "3.5").should be true
      gridin_equivalence("[3,4];[5,6]", "4").should be true
      gridin_equivalence("[3,4];[5,6]", "4.5").should be false
      gridin_equivalence("[3,4];[5,6]", "5").should be true
      gridin_equivalence("[3,4];[5,6]", "5.5").should be true
      gridin_equivalence("[3,4];[5,6]", "6").should be true
      gridin_equivalence("[3,4];[5,6]", "7").should be false

      gridin_equivalence("[1/4,1/3];[1/2,2/3]", ".249").should be false
      gridin_equivalence("[1/4,1/3];[1/2,2/3]", ".25").should be true
      gridin_equivalence("[1/4,1/3];[1/2,2/3]", ".3").should be true
      gridin_equivalence("[1/4,1/3];[1/2,2/3]", ".333").should be true
      gridin_equivalence("[1/4,1/3];[1/2,2/3]", ".334").should be false
      gridin_equivalence("[1/4,1/3];[1/2,2/3]", ".4").should be false
      gridin_equivalence("[1/4,1/3];[1/2,2/3]", ".5").should be true
      gridin_equivalence("[1/4,1/3];[1/2,2/3]", ".6").should be true
      gridin_equivalence("[1/4,1/3];[1/2,2/3]", ".666").should be true
      gridin_equivalence("[1/4,1/3];[1/2,2/3]", ".667").should be true
      gridin_equivalence("[1/4,1/3];[1/2,2/3]", ".668").should be false

      gridin_equivalence("[1/3,1/2];[2/3,3/4]", ".33").should be false
      gridin_equivalence("[1/3,1/2];[2/3,3/4]", ".333").should be true

      # Ranges and values?
      gridin_equivalence("0.2;[1/3,2/3]", '.199').should be false
      gridin_equivalence("0.2;[1/3,2/3]", '1/5').should be true
      gridin_equivalence("0.2;[1/3,2/3]", '.20').should be true
      gridin_equivalence("0.2;[1/3,2/3]", '.201').should be false
      gridin_equivalence("0.2;[1/3,2/3]", '1/4').should be false
      gridin_equivalence("0.2;[1/3,2/3]", '1/3').should be true
      gridin_equivalence("0.2;[1/3,2/3]", '1/2').should be true
      gridin_equivalence("0.2;[1/3,2/3]", '2/3').should be true
      gridin_equivalence("0.2;[1/3,2/3]", '.666').should be true
      gridin_equivalence("0.2;[1/3,2/3]", '.667').should be true
      gridin_equivalence("0.2;[1/3,2/3]", '.668').should be false
    end
  end
end
