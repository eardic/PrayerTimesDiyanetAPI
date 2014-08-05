#!/bin/env ruby
# encoding: utf-8
class NamazVaktiController < ApplicationController

  def initialize
    @browser = Watir::Browser.new :phantomjs
    @browser.goto 'http://www.diyanet.gov.tr/tr/PrayerTime/WorldPrayerTimes'
  end

  def index

  end

  def vakitler
    @browser.select_list(:name => 'Country').select params[:ulke]
    if params[:sehir]
      @browser.select_list(:name => 'State').select params[:sehir]
    end
    if params[:ilce]
      @browser.select_list(:name => 'City').select params[:ilce]
    end

    @browser.radio(:value => 'Aylik').set
    @browser.link(:text => 'Hesapla').click
    table = @browser.table(:class => 'form')
    @content = table.trs.collect { |tr| {:tarih => tr[0].text, :imsak => tr[1].text, :gunes => tr[2].text, :ogle => tr[3].text,
                                         :ikindi => tr[4].text, :aksam => tr[5].text, :yatsi => tr[6].text, :kible => tr[7].text} }
    @content.delete_at(0)
  end

end
