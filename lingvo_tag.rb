#!/usr/bin/ruby
# -*- coding: utf-8 -*-

# Class representing tag of Lingvo markup 

class LingvoTag

  def initialize(name, attributes, value =  nil)
    @name = name
    @attributes = attributes
    @children = []
    @value = value
  end

  def name
    @name
  end
  
  def value=(value)
    @value = value
  end
  
  def value
    @value
  end

  # names - tags to ignore
  def metavalue(names = nil, divider = "; ")
    ret = nil
    @children.each do |tag|
      if tag.value and (names.nil? or (!names.nil? and !names.include?(tag.name)))
        if ret
          ret += divider + tag.value
        else
          ret = tag.value
        end
      end
      if names.nil? or (!names.nil? and !names.include?(tag.name))
        chmeta = tag.metavalue(names, divider)
        if chmeta
          if ret
            ret += divider + chmeta
          else
            ret = chmeta
          end
        end
      end
    end
    return ret
  end
  
  def addChild(child)
    @children << child
  end
  
  def getFirstChild(name)
    @children.each do |tag|
      if tag.name == name
        return tag
      end
    end
    return nil
  end
  
  def getChildren(names)
    ret = []
    @children.each do |tag|
      if names.include?(tag.name)
        ret << tag
      end
    end
    return ret
  end

  def rec_to_s(prefix)
    ret = prefix+"[#@name #@attributes]: #@value"
    @children.each do |tag|
      ret += "\n"+tag.rec_to_s(prefix+"  ")
    end
    return ret
  end
  
  def to_s
    rec_to_s("")
  end

  def self.parseFirstTag(line)
    #puts "parseFirstTag(#{line})"
    r = Regexp.new(".*?\\\[(.+?)\\\]");
    m = r.match(line);
    #puts "start tag match: "+m.inspect
    if m != nil
      startTag = m[1]
      arguments = nil
      if startTag.index(" ") 
        startTag, arguments = startTag.split(" ", 2);
      end
      endTag = startTag
      if startTag[0] == "m"
        endTag = "m"
      end
      # replace * with \*
      rStartTag, rEndTag = startTag, endTag
      if startTag == "*"
        rStartTag = rEndTag = "\\\*"
      end
      if arguments
        rTag = Regexp.new("(.*?)\\\[#{rStartTag} #{arguments}\\\](.+?)\\\[\\\/#{rEndTag}\\\](.*)");
      else
        rTag = Regexp.new("(.*?)\\\[#{rStartTag}\\\](.+?)\\\[\\\/#{rEndTag}\\\](.*)");
      end
      mTag = rTag.match(line);
      if mTag == nil
        #error: no matching endtag
        raise "No matches for [#{startTag}] .. [/#{endTag}] in line '#{line}'"
      end
      #puts "tag match: "+mTag.inspect
      return startTag, arguments, mTag[1], mTag[2], mTag[3]
    end
    return nil
  end

  def self.parseLine(line, parent = nil)
    if parent.nil?
      #puts "parseLine(#{line}, nil)"
    else
      #puts "parseLine(#{line}, #{parent.name})"
    end 
    startTag, attributes, before, inner, after = LingvoTag.parseFirstTag(line)
    if startTag
      if startTag == "ex"
        #remove all [i],[com],[p] tags in [ex]
        inner = inner.gsub("[i]","").gsub("[/i]", "").gsub("[com]", "").gsub("[/com]", "").gsub("[p]", "").gsub("[/p]", "")
      elsif startTag == "m1"
        #remove all [i] tags in "m1"
        inner = inner.gsub("[i]","").gsub("[/i]", "")
      elsif startTag == "m2"
        #remove all [b] tags in "m2"
        inner = inner.gsub("[b]","").gsub("[/b]", "")
      end
      tag = LingvoTag.new(startTag, attributes)
      if !parent.nil?
        if before.strip.to_s != ''
          parent.addChild(LingvoTag.new("txt", nil, before.strip))
        end
        parent.addChild(tag)
      end
      if LingvoTag.parseFirstTag(inner) == nil
        tag.addChild(LingvoTag.new("txt", nil, inner.strip))
      else
        parseLine(inner, tag)
      end
      if !parent.nil?
        if after.to_s != ''
          if LingvoTag.parseFirstTag(after) == nil
            parent.addChild(LingvoTag.new("txt", nil, after.strip))
          else
            parseLine(after, parent)
          end
        end
      end
      return tag
    else
      parent.addChild(LingvoTag.new("txt", nil, line.strip)) unless parent.nil?
    end
    return nil
  end
  
end


#puts parseFirstTag("[m1][c darkslateblue]1)[/c] полин[/m]")
#puts parseFirstTag("[c darkslateblue]1)[/c] полин")

#str = "[m1][c darkslateblue]5)[/c] [p]тех.[/p] експлуатація з порушенням правил [p]pass.[/p] бути введеним в оману, бути обманутим[/m]"
#str = "[m1][c darkslateblue]2)[/c] абсент [com][i](напій)[/i][/com][/m]"
#tag = LingvoTag.parseLine(str)
#puts tag
#puts tag.metavalue()
#puts tag.metavalue(["c"], " ")

