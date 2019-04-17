#!/usr/bin/ruby
# -*- coding: utf-8 -*-

class Morpho
  def initialize(word, forms, type = nil)
    @word = word
    @type = type
    # forms can be array or comma separated list of words
    if forms.instance_of? Array
      @forms = forms
    elsif forms.instance_of? String
      @forms = forms.split(",")
    end
  end

  def word
    @word
  end

  def forms
    @forms
  end
  
  def posibleType
    ret = []
    if @forms.any? { |s| s.end_with?('ing') }
      ret << "v"
    end
    if @forms.any? { |s| s.end_with?('er') } && @forms.any? { |s| s.end_with?('est') }
      ret << "a"
    end
    if @forms.size == 1 && (@forms[0].end_with?('s') || @forms[0].end_with?('en'))
      ret << "n"
    end
    ret
  end

  def to_s
    ret = @word
    ret += "\t"
    type = posibleType
    ret += type.join(",") if type
    ret += "\t"
    ret += @forms.join(",") if @forms
    ret
  end
end

# process original file
=begin 
  file = File.open("/media/sf_host_dir/Dokumente/my_dev/en_uk/en_wordform.txt")
  outFile = File.open("/media/sf_host_dir/Dokumente/my_dev/en_uk/en_wordform_out.txt", 'w')
  todoFile = File.open("/media/sf_host_dir/Dokumente/my_dev/en_uk/en_wordform_todo.txt", 'w')
  
  while line = file.gets
    if line.length > 0
      if line[0] == ";" #comment
        next
      else
        data = line.split("->")
        wf = Morpho.new(data[0].strip, data[1].strip)
        todoFile.write(wf.to_s+"\n") if wf.posibleType.size != 1
        outFile.write(wf.to_s+"\n") if wf.posibleType.size == 1
      end
    end
  end
ensure
  file.close if file
  outFile.close if outFile
=end