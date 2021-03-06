
class Hash
  def get_deep(*fields)
    fields.inject(self) {|acc,e| acc[e] if acc}
  end

  def except!(*keys)
    keys.each { |key| delete(key) }
    self
  end

  def except(*keys)
    dup.except!(*keys)
  end
  
end

class String
  def is_i?
    !!(self =~ /\A[-+]?[0-9]+\z/)
  end

  BLANK_RE = /\A[[:space:]]*\z/

  def blank?
    BLANK_RE === self
  end

  def starts_with?(prefix)
    prefix.respond_to?(:to_str) && self[0, prefix.length] == prefix
  end
end

class NilClass
  def blank?
    true
  end
end

class Display

  def self.tut(message)
    Rainbow(message).bright.blue
  end

  def self.prompt(message)
    "  #{tut('> ' + message)}"
  end

end