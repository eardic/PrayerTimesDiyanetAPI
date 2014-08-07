#!/bin/env ruby
# encoding: utf-8
class NamazVaktiController < ApplicationController

  def index

  end

  def ulkeler
    require 'net/http'
    require 'uri'
    url = URI.parse('http://www.diyanet.gov.tr/tr/PrayerTime/WorldPrayerTimes')
    req = Net::HTTP::Get.new(url.to_s)
    page = Net::HTTP.start(url.host, url.port) { |http|
      http.request(req)
    }
    doc = Nokogiri::HTML(page.body)
    @country = {}
    doc.css("#Country option").each do |d|
      @country[d.attr("value")] = d.text
    end
  end

  def sehirler
    require 'net/http'
    require 'uri'
    url = URI.parse("http://www.diyanet.gov.tr/PrayerTime/FillState?countryCode=#{params[:country_id]}")
    req = Net::HTTP::Get.new(url.to_s)
    page = Net::HTTP.start(url.host, url.port) { |http|
      http.request(req)
    }
    state_array = JSON.parse(page.body.to_s)
    @states = {}
    state_array.each do |k|
      k.delete('Selected')
      @states[k['Value']] = k['Text']
    end
  end

  def ilceler
    require 'net/http'
    require 'uri'
    url = URI.parse("http://www.diyanet.gov.tr/PrayerTime/FillCity?itemId=#{params[:state_id]}")
    req = Net::HTTP::Get.new(url.to_s)
    page = Net::HTTP.start(url.host, url.port) { |http|
      http.request(req)
    }
    city_array = JSON.parse(page.body.to_s)
    @cities = {}
    city_array.each do |k|
      k.delete('Selected')
      @cities[k['Value']] = k['Text']
    end
  end

  def vakitler
    require 'net/http'
    require 'uri'
    page = Net::HTTP.post_form(URI.parse('http://www.diyanet.gov.tr/tr/PrayerTime/PrayerTimesList'),
                               {'Country' => params[:country_id],
                                'State' => params[:state_id],
                                'City' => params[:city_id],
                                'period' => params[:period] ? params[:period] : 'Aylik'})
    doc = Nokogiri::HTML(page.body)
    rows = doc.xpath('//*[@id="body"]/div/div[1]/table/tbody/tr')
    @prayer_times = rows.collect do |row|
      prayer_time = {}
      [
          [:tarih, 'td[1]/text()'],
          [:imsak, 'td[2]/text()'],
          [:gunes, 'td[3]/text()'],
          [:ogle, 'td[4]/text()'],
          [:ikindi, 'td[5]/text()'],
          [:aksam, 'td[6]/text()'],
          [:yatsi, 'td[7]/text()'],
          [:kible, 'td[8]/text()']
      ].each do |name, xpath|
        prayer_time[name] = row.at_xpath(xpath).to_s.strip
      end
      prayer_time
    end
  end

end
