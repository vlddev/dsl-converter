#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require_relative 'lingvo_tag'
require_relative 'lingvo_article'
require_relative 'dict_en_word'
require_relative 'dict_dao'

# TODO: compare with lingvo_dsl2db.rb

begin
file = File.open("lingvo_test.dsl")

con = Mysql.new('localhost', 'user', 'pwd', 'database')
dao = DictDAO.new(con)

word = ""
words = []
article = []
   while line = file.gets
     if line.length > 0 
       if line[0] == "\t"
         article << line.strip if line.strip.size > 0
       else
         if word.length > 0
             # if article.length == 0 -> read next word until article.length > 0, create links between all definotion-words
           if article.length == 0
             
             puts "article.length == 0: words ="+words.to_s
           else
             lingvoArticle = LingvoArticle.new(words, article)
             puts "words: "+words.to_s
             #puts "article: "+article.to_s
             enWords = lingvoArticle.convert_to_dict
             if enWords
               enWords.each do |enWord|
                 dao.insert(enWord)
                 #puts enWord.to_s
               end
             end
             article.clear
             words.clear
           end # if article.length == 0
         end #if word.length > 0
         word = line.strip
         words << word
       end # if line[0] == "\t"
     end #if line.length > 0
   end #while
   if word.length > 0
       # if article.length == 0 -> read next word until article.length > 0, create links between all definotion-words
     if article.length == 0
       puts "article.length == 0: words ="+words.to_s
     else
       lingvoArticle = LingvoArticle.new(words, article)
       puts "words: "+words.to_s
       #puts "article: "+article.to_s
       enWords = lingvoArticle.convert_to_dict
       if enWords
         enWords.each do |enWord|
           dao.insert(enWord)
           #puts enWord.to_s
         end
       end
       article.clear
       words.clear
     end # if article.length == 0
   end #if word.length > 0
ensure
  file.close if file
  con.close if con
end