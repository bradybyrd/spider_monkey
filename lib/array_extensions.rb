################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ArrayExtensions
  def select!
    self.reject! { |el| !yield(el) }
  end

  def delete_unless &block
    self.select! &block
    self
  end

  def differentiated_word word
    sorted = dup
    sorted << word unless sorted.include?(word)
    sorted.sort!
    sorted.each_index do |idx|
      p, this_word, n = sorted[idx-1], sorted[idx], sorted[(idx+1) % size]
      if idx == 0
        f, s = this_word.first, ''
      else
        f = this_word.differentiate(p)
        s = (this_word.first == p.first ? this_word.differentiate(n) : '') 
      end

      if this_word == word
        return f.size > s.size ? f : s
      end
    end
    nil
  end
  
  def in_group(group)
    select { |s| s.leading_group_id = group }
  end
  
  def count
    size
  end
  
  def ids
    []
  end
  
  def count(&action)
    begin
      count = 0
      self.each { |x| count = count + 1 if action.call(x) }
      return count
    rescue
      return 0
    end
  end
  
  def no_group
    select {|a| a.leading_group_id == nil }
  end
  
  def nil_or_empty?
    empty?
  end
  
  def rotate(position)
    (push self.shift(position)).flatten
  end

  def flatten_hashes
    Hash[*self.map(&:to_a).flatten]
  end
  
  
  
end
