#!/bin/env ruby
# encoding: utf-8
require 'net/http'
require 'uri'
require 'hpricot'

class NamazVaktiController < ApplicationController

  def index

  end

  def ulkeler
    cached = Rails.cache.fetch('ulkeler', expires_in: 4.weeks) do
      url = URI.parse('http://www.diyanet.gov.tr/tr/PrayerTime/WorldPrayerTimes')
      req = Net::HTTP::Get.new(url.to_s)
      page = Net::HTTP.start(url.host, url.port) { |http|
        http.request(req)
      }
      doc = Hpricot(page.body)
      @country = {}
      doc.search("#Country option").each do |d|
        @country[d.attributes["value"]] = d.inner_html
      end
      @country
    end
    render json: cached
  end

  def sehirler
    cached = Rails.cache.fetch("sehirler_#{params[:country_id]}", expires_in: 4.weeks) do
      url = URI.parse("http://www.diyanet.gov.tr/PrayerTime/FillState?countryCode=#{params[:country_id]}")
      req = Net::HTTP::Get.new(url.to_s)
      page = Net::HTTP.start(url.host, url.port) { |http|
        http.request(req)
      }
      @states = {}
      state_array = JSON.parse(page.body.to_s)
      state_array.each do |k|
        k.delete('Selected')
        @states[k['Value']] = k['Text']
      end
      @states
    end
    render json: cached
  end

  def ilceler
    cached = Rails.cache.fetch("ilceler_#{params[:state_id]}", expires_in: 4.weeks) do
      url = URI.parse("http://www.diyanet.gov.tr/PrayerTime/FillCity?itemId=#{params[:state_id]}")
      req = Net::HTTP::Get.new(url.to_s)
      page = Net::HTTP.start(url.host, url.port) { |http|
        http.request(req)
      }
      @cities = {}
      city_array = JSON.parse(page.body.to_s)
      city_array.each do |k|
        k.delete('Selected')
        @cities[k['Value']] = k['Text']
      end
      @cities
    end
    render json: cached
  end
  
  def vakitler
    period = params[:period] ? params[:period] : 'Aylik'
    expire = 2.weeks # Aylik icin
    if period == 'Haftalik'
      expire = 3.days # Haftalik icin
    end
    cached = Rails.cache.fetch("vakitler_#{params[:country_id]}_#{params[:state_id]}_#{params[:city_id]}_#{period}", expires_in: expire) do
      getUrl = URI.parse("http://www.diyanet.gov.tr/tr/PrayerTime/WorldPrayerTimes")
      postUrl = URI.parse('http://www.diyanet.gov.tr/tr/PrayerTime/PrayerTimesList')
      postResponse = Net::HTTP.start(getUrl.host, getUrl.port) { |http|
        # Get Security parameters
        getReq = Net::HTTP::Get.new(getUrl.to_s)
        getResponse = http.request(getReq)
        cookies = getResponse.response['set-cookie']
        getDoc = Hpricot(getResponse.body)
        sfidElem = getDoc.at("input[@name='as_sfid']")
        fidElem = getDoc.at("input[@name='as_fid']")
        if !sfidElem.nil?
          as_sfid = sfidElem["value"]
        end
        if !fidElem.nil?
          as_fid = fidElem["value"]
        end
        #puts "Sec Params:#{as_sfid}  #{as_fid}"
        # Get Times Table
        postReq =  Net::HTTP::Post.new(postUrl.to_s)
        postReq['Cookie'] = cookies
        postReq.set_form_data( {'Country' => params[:country_id],
                                'State' => params[:state_id],
                                'City' => params[:city_id],
                                'period' => period,
                                'as_sfid' => as_sfid,
                                'as_fid' => as_fid } )
        http.request(postReq)
      }

      doc = Hpricot(postResponse.body)
      rows = doc.search('//*[@id="body"]/div/div[1]/table/tbody/tr')
      @prayer_times = rows.collect do |row|
        prayer_time = {}
        [
            [:tarih, 'td[1]'],
            [:imsak, 'td[2]'],
            [:gunes, 'td[3]'],
            [:ogle,  'td[4]'],
            [:ikindi,'td[5]'],
            [:aksam, 'td[6]'],
            [:yatsi, 'td[7]'],
            [:kible, 'td[8]']
        ].each do |name, xpath|
          prayer_time[name] = row.search(xpath).inner_html.to_s.strip
        end
        prayer_time
      end
      @prayer_times.delete_at(0)
      @prayer_times
    end
    render json: cached
  end

end
