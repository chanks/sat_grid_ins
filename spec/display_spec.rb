require 'spec_helper'

describe GridIn, "#to_display" do
  def display(input)
    GridIn.new(input).to_display
  end

  it "should handle integers" do
    display("1234").should == "1234"
    display("1234;5678").should == "1234 or 5678"
    display("12;34;56").should == "12, 34, or 56"
  end

  it "should handle decimals" do
    display(".123").should == ".123"
    display(".123;.567").should == ".123 or .567"
    display(".12;.34;.56").should == ".12, .34, or .56"
  end

  it "should handle rationals" do
    display("2/3").should == "2/3"
    display("2/3;5/6").should == "2/3 or 5/6"
    display("1/2;2/3;3/4").should == "1/2, 2/3, or 3/4"
  end

  it "should handle exclusive ranges" do
    display("(1,5)").should == "1 < x < 5"
    display("(1,5);(8,12)").should == "1 < x < 5 or 8 < x < 12"
    display("(1,5);(8,12);(18,24)").should == "1 < x < 5, 8 < x < 12, or 18 < x < 24"
  end

  it "should handle inclusive ranges" do
    display("[1,5]").should == "1 ≤ x ≤ 5"
    display("[1,5];[8,12]").should == "1 ≤ x ≤ 5 or 8 ≤ x ≤ 12"
    display("[1,5];[8,12];[18,24]").should == "1 ≤ x ≤ 5, 8 ≤ x ≤ 12, or 18 ≤ x ≤ 24"
  end

  it "should handle mixed ranges" do
    display("[1,5)").should == "1 ≤ x < 5"
    display("(1,5];(8,12]").should == "1 < x ≤ 5 or 8 < x ≤ 12"
    display("[1,5);(8,12];[18,24)").should == "1 ≤ x < 5, 8 < x ≤ 12, or 18 ≤ x < 24"
  end

  it "should handle lists of mixed values" do
    display("2;.5;6/7;(9.5,10.5]").should == "2, .5, 6/7, or 9.5 < x ≤ 10.5"
  end
end
