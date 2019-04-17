#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require 'mysql'
require_relative 'dict_en_word'
require_relative 'morpho'

# Database access

class DictDAO

  def initialize(connection)
    @connection = connection
    @connection.autocommit false
    @connection.query "SET NAMES utf8"
  end

  def insert(en_word)
    ps_en_inf = @connection.prepare "INSERT INTO en_inf(inf, type) VALUES(?,?)"
    ps_tr = @connection.prepare "INSERT INTO tr_en_uk(order_nr, fk_en_id, uk_word, ctx) VALUES(?,?,?,?)"
    ps_ex = @connection.prepare "INSERT INTO ex_tr_en_uk(order_nr, fk_tr_en_uk, fk_en_id, en_frase, uk_frase, ctx) VALUES(?,?,?,?,?,?)"
    ps_en_inf.execute(en_word.word, DictEnWord.typeToInt(en_word.type)) 
    # get id of new word
    wordId = getLastInsertedId
    trOrder = 1
    
    en_word.translations.each do |tr|
      puts "insert tr: #{trOrder}, #{wordId}, #{tr.value}, #{tr.context}"
      ps_tr.execute(trOrder, wordId, tr.value, tr.context)
      # get id of new translation
      trId = getLastInsertedId
      trOrder += 1
      exOrder = 1
      tr.examples.each do |ex|
        puts "insert ex: #{exOrder}, #{trId}, nil, #{ex.frase}, #{ex.translation}, #{ex.context}"
        ps_ex.execute(exOrder, trId, nil, ex.frase, ex.translation, ex.context)
        exOrder += 1
      end
    end
    exOrder = 1
    en_word.examples.each do |ex|
      puts "insert ex: #{exOrder}, nil, #{wordId}, #{ex.frase}, #{ex.translation}, #{ex.context}"
      ps_ex.execute(exOrder, nil, wordId, ex.frase, ex.translation, ex.context)
      exOrder += 1
    end
    @connection.commit
  rescue Mysql::Error => e
    puts e
    @connection.rollback
  ensure
    ps_en_inf.close if ps_en_inf
    ps_tr.close if ps_tr
    ps_ex.close if ps_ex
  end

  def insert2(en_word)
    ps_en_inf = @connection.prepare "INSERT INTO en_inf(inf, type) VALUES(?,?)"
    ps_tr = @connection.prepare "INSERT INTO tr_en_uk(order_nr, fk_en_id, uk_word, example) VALUES(?,?,?,?)"
    ps_en_inf.execute(en_word.word, DictEnWord.typeToInt(en_word.type)) 
    # get id of new word
    wordId = getLastInsertedId
    trOrder = 1
    
    en_word.translations.each do |tr|
      trStr = ""
      trStr = tr.value if tr.value 
      trStr = trStr + tr.context if tr.context
      exStr = ""
      tr.examples.each do |ex|
        if exStr.length > 0
          exStr = exStr + "|"
        end
        if ex.context
          exStr = exStr + " #{ex.frase} → #{ex.translation} (#{ex.context}) "
        else
          exStr = exStr + " #{ex.frase} → #{ex.translation} "
        end
      end
      # replace something like "(амер.)амер." to "(амер.)"
      if trStr.start_with?("(")
        indEnd = trStr.index(')')
        if !indEnd.nil?
          ctxStr = trStr[1..trStr.index(')')-1]
          if trStr[indEnd+1..trStr.length].start_with?(ctxStr)
            #puts "tr: #{trStr}, [ replace #{ctxStr} ] -> #{trStr.sub(")"+ctxStr,")")}"
            trStr = trStr.sub(")"+ctxStr,")")
          end
        end
      end
      puts "insert tr: #{trOrder}, #{wordId}, #{trStr}, [ #{exStr} ]"
      ps_tr.execute(trOrder, wordId, trStr, exStr)
      trOrder += 1
    end
    en_word.examples.each do |ex|
      if ex.context
        trStr = "#{ex.frase} → #{ex.translation} (#{ex.context})"
      else
        trStr = "#{ex.frase} → #{ex.translation}"
      end
      puts "insert examples tr: #{trOrder}, #{wordId}, nil, [#{trStr}]"
      ps_tr.execute(trOrder, wordId, nil, trStr)
      trOrder += 1
    end
    @connection.commit
  rescue Mysql::Error => e
    puts e
    @connection.rollback
  ensure
    ps_en_inf.close if ps_en_inf
    ps_tr.close if ps_tr
  end
  
  def getLastInsertedId
    rs = @connection.query("SELECT last_insert_id()")
    rs.fetch_row[0]
  end

  def generateWordforms(wfFile)
    ps_en_wf = @connection.prepare "INSERT INTO en_wf(fk_inf, wf) VALUES(?,?)"
    # read predefined forms from file
    file = File.open(wfFile)
    wfHash = Hash.new
    while line = file.gets
      if line.length > 0
        if line[0] == ";" #comment
          next
        else
          data = line.split("\t")
          word = data[0].strip
          type = data[1].strip
          forms = word+","+data[2].strip
          if type
            wf = Morpho.new(word, forms, type)
            wfHash[word+"_"+type] = wf
          else
            wf = Morpho.new(word, forms)
            wfHash[word] = wf
          end
        end
      end
    end
    
    puts "wfHashe.size = "+wfHash.size.to_s

    # generate/fill forms for words in dict
    rs = @connection.query("SELECT id, inf, type, case type when 1 then 'n' when 5 then 'a' when 16 then 'v' else type end as itype FROM en_inf")
    rs.each_hash do |row|
      #puts "row: "+row.to_s
      key = row['inf']+"_"+row['itype']
      if wfHash.key?(key)
        wmorph = wfHash[key]
        #puts "wfs from file: "+wmorph.to_s
        wmorph.forms.uniq.each do |form|
          ps_en_wf.execute(row['id'], form)
        end
      else
        #generate forms
        forms = []
        word = row['inf']
        forms.push(word)
        if word.include? " " #word with space -> generate nothing
          #puts "word with space -> generate nothing"
        elsif row['type'] == "1" #noun
          if word.end_with?("s","x")
            forms.push(word+"es")
          elsif word.end_with?("y")
            forms.push(word.chop+"ies")
          else
            forms.push(word+"s")
          end
        elsif row['type'] == "5" #adjective
          forms.push(word+"er")
          forms.push(word+"est")
        elsif row['type'] == "16" #verb
          if word.end_with?("set") # doubled 't': "beset"
            forms.push(word+"s")
            forms.push(word+"ting")
            forms.push(word+"ted")
          elsif word.end_with?("p") # doubled 'p': "trip, clip"
            forms.push(word+"s")
            forms.push(word+"ping")
            forms.push(word+"ped")
          elsif word.end_with?("y") 
            if word.end_with?("ay","ey","uy","oy") # "betray"
              forms.push(word+"s")
              forms.push(word+"ing")
              forms.push(word+"ed")
            else #'y' replaced with 'i' ("bully")
              forms.push(word.chop+"ies")
              forms.push(word.chop+"ying")
              forms.push(word.chop+"ied")
            end
          elsif word.end_with?("e") # debate -> debated, debating 
            forms.push(word+"s")
            forms.push(word.chop+"ing")
            forms.push(word+"d")
          elsif word.end_with?("x","z") # fix -> fixes; buzz -> buzzes
            forms.push(word+"es")
            forms.push(word+"ing")
            forms.push(word+"ed")
          else
            forms.push(word+"s")
            forms.push(word+"ing")
            forms.push(word+"ed")
          end
        else #all others unchanged
          #puts "other - "+row['type'].to_s
        end
        #puts "generated wfs: "+forms.to_s
        forms.uniq.each do |form|
          ps_en_wf.execute(row['id'], form)
        end
      end
    end
    @connection.commit
  rescue Mysql::Error => e
    puts e
    @connection.rollback
  ensure
    file.close if file
    ps_en_wf.close if ps_en_wf
  end

end

=begin
  con = Mysql.new('localhost', 'user', 'pwd', 'database')
  dao = DictDAO.new(con)
  dao.generateWordforms("en_wordforms.txt")
  
  #ps_tr = con.prepare "INSERT INTO tr_en_uk(order_nr, fk_en_id, uk_word, ctx) VALUES(?,?,?,?)"
  #ps_tr.execute(1, 1, "tr.value", nil)

rescue Mysql::Error => e
  puts e.errno
  puts e.error

ensure
  con.close if con
=end