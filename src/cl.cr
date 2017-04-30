require "logger"

# Logger #######################################################################

LOG = Logger.new(STDOUT)
LOG.level = Logger::INFO
LOG.formatter = Logger::Formatter.new do |severity, _datetime, _progname, message, io|
  io << case severity
  when "DEBUG"
    ":: "
  when "INFO"
    ">> "
  when "WARN"
    "** "
  when "ERROR"
    "!! "
  when "FATAL"
    "   " # FIXME: Bullet for FATAL
  end
  io << message
  io << "..." if severity == "INFO"
end

# Main #########################################################################

LOG.info("Help!")
