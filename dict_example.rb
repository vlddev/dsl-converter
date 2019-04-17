#!/usr/bin/ruby
# -*- coding: utf-8 -*-
class DictExample
  def initialize(frase, translation, context = nil)
    @frase = frase
    @translation = translation
    @context = context
  end

  def frase
    @frase
  end

  def translation
    @translation
  end

  def context
    @context
  end

  def to_s
    ret = "#@frase -> #@translation"
    if @context && @context.size > 0
      ret = "(#@context) " + ret 
    end
    ret
  end
end