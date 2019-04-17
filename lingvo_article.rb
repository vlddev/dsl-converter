#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require_relative 'lingvo_tag'
require_relative 'dict_en_word'
require_relative 'dict_dao'

# Class representing Lingvo dictionary article

class LingvoArticle
  def initialize(words, article)
    @words = words
    @word = words[0]
    @article = article
    @tags = []
    @article.each do |line|
      @tags << LingvoTag.parseLine(line);
    end
  end
  
  def word
    @word
  end
  
  def words
    @words
  end

  def to_s
    ret = "#@word =>"
    @tags.each do |tag|
      ret += "\n"+tag.to_s
    end
    return ret
  end

  def convert_to_dict
    ret = []
    word = nil
    tr = nil
    if @words.length > 1
      puts "create redirects to "+@word
      for i in 1..(@words.length-1)
        word = DictEnWord.new(@words[i], "redirect")
        word.addTranslation(DictTranslation.new(@word, "redirect"))
        ret << word
      end 
      word = nil
    end
    @tags.each do |tag|
      #puts tag.name
      if ["m","m1"].include?(tag.name)
        if tagP = tag.getFirstChild("p")
          # check type
          if DictEnWord.hasType?(tagP.getFirstChild("txt").value)
            if tr && word
              word.addTranslation(tr)
              tr = nil
            end
            if word
              # store word
              ret << word
            end
            word = DictEnWord.new(@word, tagP.getFirstChild("txt").value)
          else
            puts "Warning: ignore unknown type: #{tagP.getFirstChild("txt").value}"
            if tag.name == "m1"
              if @tags.size == 1
                if word
                  #store word
                  ret << word
                end
                word = DictEnWord.new(@word, "unknown")
              end
              if tr && word
                word.addTranslation(tr)
                tr = nil
              end
              tr = DictTranslation.new(
                #"(#{tagP.getFirstChild("txt").value})" + tag.metavalue(["c"], " "), # getAllTexts
                tag.metavalue(["c"], " "), # getAllTexts
                nil)
            end
          end
        else # not p
          if tag.name == "m1"
            if tr && word
              word.addTranslation(tr)
              tr = nil
            end
            tr = DictTranslation.new(
              tag.metavalue(["c"], " "), # getAllTexts
              nil) 
          end
        end # p
      #end m, m1
      elsif tag.name == "m3"
        tagEx = tag.getFirstChild("*").getFirstChild("ex")
        if tagEx
          if !tr
            puts "Warning: example '#{tagEx.getChildren("txt").map{|txt| txt.value}.join(" ")}' without translation in #@word"
            tr = DictTranslation.new("","")
          end
          tr.addExapmle(DictExample.new(
            tagEx.getFirstChild("lang").getChildren("txt").map{|txt| txt.value}.join(" ").gsub("~", @word), 
            tagEx.getChildren("txt").map{|txt| txt.value}.join(" ")
            ))
        end 
      elsif tag.name == "m2"
        tagC1, tagC2 = tag.getChildren("c")
        if word && tagC1 && tagC2
          word.addExapmle(DictExample.new(
            tagC1.getFirstChild("txt").value + " " + tagC2.getFirstChild("lang").getChildren("txt").map{|txt| txt.value}.join(" ").gsub("~", @word), 
            tagC2.getChildren("txt").map{|txt| txt.value}.join(" ")
            ))
        else
          puts "Warning: [m2] without word #{tag.inspect}" if !word
          puts "Warning: first [c] in [m2] not found #{tag.inspect}" if !tagC1
          puts "Warning: second [c] in [m2] not found #{tag.inspect}" if !tagC2
        end
      end
    end
    if tr && word
      word.addTranslation(tr)
      tr = nil
    end
    if word
      # store word
      ret << word
    end
    return ret
  rescue => e
    puts to_s
    raise e
  end

  def convert_to_dict_ctx
    ret = []
    word = nil
    tr = nil
    if @words.length > 1
      puts "create redirects to "+@word
      for i in 1..(@words.length-1)
        word = DictEnWord.new(@words[i], "redirect")
        word.addTranslation(DictTranslation.new(@word, "redirect"))
        ret << word
      end 
      word = nil
    end
    @tags.each do |tag|
      #puts tag.name
      if ["m","m1"].include?(tag.name)
        if tagP = tag.getFirstChild("p")
          # check type
          if DictEnWord.hasType?(tagP.getFirstChild("txt").value)
            if tr && word
              word.addTranslation(tr)
              tr = nil
            end
            if word
              # store word
              ret << word
            end
            word = DictEnWord.new(@word, tagP.getFirstChild("txt").value)
          else
            puts "Warning: ignore unknown type: #{tagP.getFirstChild("txt").value}"
            if tag.name == "m1"
              if @tags.size == 1
                if word
                  #store word
                  ret << word
                end
                word = DictEnWord.new(@word, "unknown")
              end
              if tr && word
                word.addTranslation(tr)
                tr = nil
              end
              tr = DictTranslation.new(
                tag.getChildren("txt").map{|txt| txt.value}.join(" "), # getAllTexts
                tag.getChildren(["com","p"]).map{|p| p.metavalue}.join("; ")) # getContexts from [p]
            end
          end
        else # not p
          if tag.name == "m1"
            if tr && word
              word.addTranslation(tr)
              tr = nil
            end
            tr = DictTranslation.new(
              tag.getChildren("txt").map{|txt| txt.value}.join(" "), # getAllTexts
              tag.getChildren(["com","p"]).map{|p| p.metavalue}.join("; ")) # getContexts from [p]
          end
        end # p
      #end m, m1
      elsif tag.name == "m3"
        tagEx = tag.getFirstChild("*").getFirstChild("ex")
        if tagEx
          if !tr
            puts "Warning: example '#{tagEx.getChildren("txt").map{|txt| txt.value}.join(" ")}' without translation in #@word"
            tr = DictTranslation.new("","")
          end
          tr.addExapmle(DictExample.new(
            tagEx.getFirstChild("lang").getChildren("txt").map{|txt| txt.value}.join(" ").gsub("~", @word), 
            tagEx.getChildren("txt").map{|txt| txt.value}.join(" ")
            ))
        end 
      elsif tag.name == "m2"
        tagC1, tagC2 = tag.getChildren("c")
        if word && tagC1 && tagC2
          word.addExapmle(DictExample.new(
            tagC2.getFirstChild("lang").getChildren("txt").map{|txt| txt.value}.join(" ").gsub("~", @word), 
            tagC2.getChildren("txt").map{|txt| txt.value}.join(" "),
            tagC1.getFirstChild("txt").value
          ))
        else
          puts "Warning: [m2] without word #{tag.inspect}" if !word
          puts "Warning: first [c] in [m2] not found #{tag.inspect}" if !tagC1
          puts "Warning: second [c] in [m2] not found #{tag.inspect}" if !tagC2
        end
      end
    end
    if tr && word
      word.addTranslation(tr)
      tr = nil
    end
    if word
      # store word
      ret << word
    end
    return ret
  rescue => e
    puts to_s
    raise e
  end

end