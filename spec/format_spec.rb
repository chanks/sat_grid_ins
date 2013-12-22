require 'spec_helper'

describe "GridIn.format" do
  it "should format input to be a valid gridin" do
    GridIn.format(nil).should == "    "
    GridIn.format("").should == "    "
    GridIn.format("7").should == "   7"
    GridIn.format("77").should == "  77"
    GridIn.format("777").should == " 777"
    GridIn.format("1234").should == "1234"
    GridIn.format("12345").should == "1234"
  end

  it "should strip invlid characters from the input" do
    GridIn.format("(12345").should  == "1234"
    GridIn.format("1/3").should     == " 1/3"
    GridIn.format("[1/3").should    == " 1/3"
    GridIn.format("1/3;2/3").should == " 1/3"
  end

  it "shouldn't mess with spaces in its input" do
    GridIn.format("123 ").should == "123 "
    GridIn.format(" 123").should == " 123"
  end

  it "shouldn't modify its input" do
    s = "12345"
    GridIn.format(s).should == "1234"
    s.should == "12345"

    s = "(12345"
    GridIn.format(s).should == "1234"
    s.should == "(12345"
  end
end
