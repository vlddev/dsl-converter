#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require_relative 'dict_example'

class DictTranslation
  def initialize(value, context = nil)
    @value = value
    @context = context
    @examples = []
  end

  def value
    @value
  end

  def context
    @context
  end

  def addExapmle(ex)
    @examples << ex
  end
  
  def examples
    @examples
  end
  
  def to_s
    ret = "#@value"
    ret += "(#@context)" unless !@context
    @examples.each do |ex|
      ret += "\n  "+ex.to_s
    end
    return ret
  end
end