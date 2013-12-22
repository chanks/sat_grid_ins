require 'spec_helper'

describe "GridIn#valid_response?" do
  def accept(string)
    GridIn.new(string).should be_valid_response
  end

  def reject(string)
    GridIn.new(string).should_not be_valid_response
  end

  it "should accept four digits" do
    accept "6326"
  end

  it "should accept a decimal" do
    accept ".326"
    accept " .32"
  end

  it "should accept a slash" do
    accept "20/3"
  end

  it "should accept whitespace" do
    accept " 2/3"
    accept "   3"
    accept "  .3"
  end

  it "should accept decimals within rationals" do
    accept ".6/7"
    accept "6/.7"
  end

  it "should reject non-digits" do
    reject "blah"
  end

  it "should reject strings that aren't four characters long" do
    reject "352"
    reject "32352"
    reject "3235 "
    reject " 2352"
  end

  it "should reject bad whitespace" do
    reject "35\n2"
    reject "323\n"
    reject "35\t2"
    reject "323\t"
  end

  it "should reject strings that start with a zero" do
    reject "0.6 "
    reject "0.68"
    reject "0006"
    reject "01/3"
  end

  it "should reject strings with slashes in the first or last places" do
    reject "/523"
    reject "523/"
  end
end
