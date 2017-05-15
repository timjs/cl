NL = "\n"

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

class File
  def self.create(filename, mode = "w", **rest)
    # NOTE: yielding the file is better than capturing the block, this way it will be inlined!
    self.open(filename, mode, **rest) do |file|
      yield file
    end
  end
end

enum Logger::Severity
  def self.from_s(level : String)
    case level.downcase
    when "debug"
      DEBUG
    when "info"
      INFO
    when "warn"
      WARN
    when "error"
      ERROR
    when "fatal"
      FATAL
    else
      UNKNOWN
    end
  end
end
