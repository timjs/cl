class String
  def quote
    String.build(self.bytesize + 2) do |str|
      str << "`" << self << "`"
    end
  end

  def to_path
    gsub('.', File::SEPARATOR)
  end

  def from_path
    gsub(File::SEPARATOR, '.')
  end
end
