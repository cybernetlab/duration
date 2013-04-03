require 'spec_helper'
require 'duration'

describe Duration do
  before :each do
    @d = Duration.new
  end

  it 'must have getters and setters for years, months, weeks, days, hours, minutes and seconds' do
#    puts "!!! #{Duration.superclass}"
    @d.years = 2
    @d.years.should eq 2
    @d.years = '20'
    @d.years.should eq 20
    expect {@d.years = []}.to raise_error ArgumentError
    expect {@d.years = -5}.to raise_error ArgumentError

    @d.months = 1; @d.months.should eq 1
    @d.weeks = 1; @d.weeks.should eq 1
    @d.days = 1; @d.days.should eq 1
    @d.hours = 1; @d.hours.should eq 1
    @d.minutes = 1; @d.minutes.should eq 1
    @d.seconds = 1; @d.seconds.should eq 1
  end

  it 'must set years, months and so on throw constructor' do
    d = Duration.new(years: 5, months: 3)
    d.years.should eq 5
    d.months.should eq 3
    d.days.should eq 0
  end

  it 'must allow positive and negative durations' do
    @d.positive?.should be_true
    @d.negative?.should be_false
    @d.negative = true
    @d.positive?.should be_false
    @d.negative?.should be_true
    @d.positive = true
    @d.positive?.should be_true
    @d.negative?.should be_false
  end

  it 'must have `accurate?` and `nominal?` methods' do
    @d.accurate?.should be_true
    @d.nominal?.should be_false
    @d.years = 3
    @d.accurate?.should be_false
    @d.nominal?.should be_true
    @d.years = 0
    @d.hours = 5
    @d.accurate?.should be_true
    @d.nominal?.should be_false
  end

  it 'must have accuracy options' do
    expect {@d.accuracy = 'weeks'}.to raise_error ArgumentError
    @d.accuracy = 2; @d.accuracy.should eq :days
    @d.accuracy = 'hours'; @d.accuracy.should eq :hours 
    d = Duration.new(accuracy: :months)
    d.accuracy.should eq :months
  end

  it 'must have `iso8601` method' do
    @d.iso8601.should eq 'PT0S'
    @d.weeks = 5
    @d.years = 3
    @d.iso8601.should eq 'P5W'
    @d.weeks = 0
    @d.iso8601.should eq 'P3Y'
    @d.hours = 10
    @d.iso8601.should eq 'P3YT10H'
    @d.accuracy = :months
    @d.iso8601.should eq 'P3Y'
    @d.months = 10
    @d.days = 7
    @d.iso8601.should eq 'P3Y10M'
    @d.iso8601(accuracy: :days).should eq 'P3Y10M7D'
  end

  it 'must allow fraction functionality' do
    @d.frac_digits.should eq 0
    @d.frac_digits = 1
    @d.frac_digits.should eq 1
    @d.years = 3.1
    @d.minutes = 40.563
    @d.iso8601.should eq 'P3YT40.6M'
    @d.frac_digits = 2
    @d.iso8601.should eq 'P3YT40.56M'
    @d.minutes = 0
    @d.iso8601.should eq 'P3.1Y'

    @d.frac_accuracy.should eq :undefined
    @d.frac_accuracy = :seconds
    @d.seconds = 35.731
    @d.minutes = 10.15
    @d.iso8601.should eq 'P3YT10M35.73S'
    @d.seconds = 0
    @d.iso8601.should eq 'P3YT10M'

    @d.seconds = 48.654
    @d.frac_sep = ','
    @d.iso8601.should eq 'P3YT10M48,65S'

    @d.negative = true
    @d.iso8601.should eq '-P3YT10M48,65S'
  end

  it 'must allow alternative format' do
    @d.alter.should be_false
    @d.years = 3
    @d.iso8601(alter: true).should eq 'P00030000'
    @d.minutes = 59
    @d.alter = true
    @d.iso8601.should eq 'P00030000T005900'
    @d.iso8601(alter_sep: true).should eq 'P0003-00-00T00:59:00'
    @d.negative = true
    @d.iso8601.should eq '-P00030000T005900'
  end

  it 'must creates from string representation' do
    d = Duration.new 'P00030000'
    d.alter.should be_true
    d.years.should eq 3
    d.accurate?.should be_false
    d = Duration.new 'P3YT2M30.5S'
    d.alter.should be_false
    d.years.should eq 3
    d.months.should eq 0
    d.minutes.should eq 2
    d.seconds.should eq 30.5
    d = Duration.new '-P3YT2M30.5S'
    d.positive?.should be_false
  end
end
