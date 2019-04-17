#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require 'mysql'

# Wiktionary DB access
# Extract transcription from english Wiktionary

class WiktionaryDAO
  def initialize(connection)
    @connection = connection
    @connection.autocommit false
    @connection.query "SET NAMES utf8"
  end

  def getIpaFromPage(word)
    ret = nil
    res = @connection.query(
    "SELECT text.old_text  FROM page, revision, text \
      where revision.rev_page = page.page_id and text.old_id = revision.rev_text_id \
      and page_namespace = 0 \
      and page_title = '"+word+"'")
    row = res.fetch_row
    if !row.nil?
      #puts row[0]
      ret = getIPA(row[0])
    end
    res.free
    return ret
  rescue Mysql::Error => e
    puts e
  end

  def getIPA(page)
    ret = Hash.new
    page.lines().each do |line|
      ipaInd = line.index("{{IPA|")
      if !ipaInd.nil? and !line.index("lang=en",ipaInd).nil?
        # if contains {{a|UK}} - UK-transcription
        if !line.index("{{a|UK}}").nil? and ret["uk"].nil?
          ret["uk"] = line[ipaInd+6 .. line.index("|",ipaInd+6)-1]
        # if contains {{a|US}} - US-transcription
        elsif !line.index("{{a|US}}").nil? and ret["us"].nil?
          ret["us"] = line[ipaInd+6 .. line.index("|",ipaInd+6)-1]
        # if contains general en-transcription
        elsif ret["en"].nil?
          ret["en"] = line[ipaInd+6 .. line.index("|",ipaInd+6)-1]
        end

      # qualifiers: {{qualifier|unstressed}}; {{qualifier|stressed}}
      end
    end
    return ret
  end

  def self.process
    freqCon = Mysql.new('10.0.2.2', 'user', 'pwd', 'vdict_01')
    wikiCon = Mysql.new('10.0.2.2', 'user', 'pwd', 'en_wiktionary')

    dao = WiktionaryDAO.new(wikiCon)

    freqCon.query "SET NAMES utf8"
    ps_update = freqCon.prepare "UPDATE en_frequency SET trans = ? WHERE rank = ?"
    res = freqCon.query("select word, rank from en_frequency order by rank")
    i = 0
    res.each do |row|
      puts "word: #{row[0]}, #{row[1]}"
      ipaHash = dao.getIpaFromPage(row[0])
      if !ipaHash.nil? and ipaHash.length > 0
        strIpa = nil
        if ipaHash["uk"].nil? and ipaHash["us"].nil? and !ipaHash["en"].nil?
          strIpa = ipaHash["en"]
        elsif !ipaHash["uk"].nil? and !ipaHash["us"].nil?
          if ipaHash["uk"] == ipaHash["us"]
            strIpa = ipaHash["uk"]
          else
            strIpa = "US: #{ipaHash["us"]}; UK:#{ipaHash["uk"]}"
          end
        else
          if !ipaHash["uk"].nil?
            strIpa = ipaHash["uk"]
          elsif !ipaHash["us"].nil?
            strIpa = ipaHash["us"]
          end
        end
        if !strIpa.nil?
          ps_update.execute(strIpa, row[1])
          puts "IPA: "+strIpa
        end
        ipaHash.each {|key, value| puts "#{key}: #{value}" }
      else
        puts "IPA notfound"
      end
      i += 1
      #break if i > 10
    end

  rescue Mysql::Error => e
    puts e.errno
    puts e.error

  ensure
    freqCon.close if freqCon
    wikiCon.close if wikiCon
  end

end

begin
  WiktionaryDAO.process
end