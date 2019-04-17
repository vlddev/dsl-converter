#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require_relative 'dict_translation'
require_relative 'dict_example'

# Class representing target dictionary article

class DictEnWord
  @@types=["adj", "adv", "conj", "int", "n", "num", "part", "prep", "pron", "v","redirect"]
  @@typeHash={
    "adj" => 5,
    "adv" => 6,
    "conj" => 7,
    "int" => 8,
    "n" => 1,
    "num" => 9,
    "part" => 13,
    "prep" => 12,
    "pron" => 10,
    "v" => 16,
    "redirect" => 80,
    "unknown" => -1}
  
  def initialize(word, type)
    @word = word
    @type = type
    @translations = []
    @examples = []
  end

  def word
    @word
  end

  def type
    @type
  end

  def addTranslation(tr)
    @translations << tr
  end

  def translations
    @translations
  end
  
  def addExapmle(ex)
    @examples << ex
  end
  
  def examples
    @examples
  end

  def self.hasType?(type)
    @@types.include?(type)
  end
  
  def self.typeToInt(type)
    @@typeHash[type]
  end
  
  
  def to_s
    ret = "#@word, #@type"
    @translations.each do |tr|
      ret += "\n  "
      ret += "(#{tr.context}) " if tr.context
      ret += tr.value
      tr.examples.each do |ex|
        ret += "\n    " + ex.to_s
      end
    end
    @examples.each do |ex|
      ret += "\n  " + ex.to_s
    end
    return ret
  end
  
  def self.test
    word = DictEnWord.new("able", "adj")
    tr = DictTranslation.new("спроможний, здатний; умілий, вправний","ctx")
    tr.addExapmle(DictExample.new("to be able", "бути спроможним, могти")) 
    tr.addExapmle(DictExample.new("to be able to swim", "уміти плавати"))
    word.addTranslation(tr) 
    tr = DictTranslation.new("здібний, талановити")
    tr.addExapmle(DictExample.new("able speech", "талановита промова")) 
    word.addTranslation(tr)
    word.addTranslation(DictTranslation.new("компетентний, правоздатний", "юр.")) 
    word.addTranslation(DictTranslation.new("з добрими морехідними даними", "мор.")) 
    puts word
    word
  end
end