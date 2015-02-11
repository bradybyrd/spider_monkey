################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module StringExtensions
    
  def differentiate other
    res = []
    chars = split('')
    begin
      res << chars.shift
    end until res.join != other[0..res.size-1] || chars.empty?
    res.join
  end
  
  def format # PP - This looks very dirty. Check if there is any way to do Multiple-gsub
    gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('#', '&quot;').gsub("'", "&#39;")
  end
  
  def nil_or_empty?
    strip.empty?
  end
  
  def strip_quotes
      gsub(/\A['"]+|['"]+\Z/, "")
  end

  def valid_json?
    begin
      JSON.parse(self)
      return true
    rescue Exception => e
      return false
    end
  end  

  # allow to marge nuber values in strings Java Opts like
  # string "-server -XX:+UseCompressedOops  -XX:PermSize=256m -Xmx1024m -Xms512m -Xss2048k"
  # marged with "-XX:PermSize=64m -Xmx128m -Xms32m -Xss2048k"
  # will retrun "-server -XX:+UseCompressedOops  -XX:PermSize=64m -Xmx128m -Xms32m -Xss2048k"
  def merge_opts!(source)
    source.split(/\s/).each do |stm|
      key, value = stm.split("=")
      if value
        gsub!(/#{key}=([^\s]*)/, "#{key}=#{value}") 
      else
        l,r = key.split(/\d+/)
        if r
          gsub!(/#{l}\d+#{r}/, key) 
        else
          replace "#{self} #{key}"
        end   
      end 
    end
    self  
  end  

end
