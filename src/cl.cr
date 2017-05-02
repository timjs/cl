require "logger"
require "colorize"
require "option_parser"

# Logger #######################################################################

log = Logger.new(STDOUT)
log.level = Logger::INFO
log.formatter = Logger::Formatter.new do |severity, _datetime, _progname, message, io|
  io << case severity
  when "DEBUG"
    ":: ".colorize.white
  when "INFO"
    ">> ".colorize.green
  when "WARN"
    "** ".colorize.yellow
  when "ERROR", "FATAL" # FIXME: Bullet for FATAL
    "!! ".colorize.red
  end
  io << message
  io << "..." if severity == "INFO"
end

# Extensions ###################################################################

class String
  def quote
    String.build(self.bytesize + 2) do |str|
      str << "`" << self << "`"
    end
  end
end

# Project ######################################################################

class Project
  def self.init
  end

  def initialize
  end

  def show_info
  end

  def show_types
  end

  def unlit
  end

  def build
  end

  def run
  end

  def clean
  end

  def prune
  end
end

# Main #########################################################################

USAGE = "\
Clean command line tools

Usage:
    cl <command> [<arguments>...]
    cl [options]

Commands:
    help        Show this message
    init        Initialise new project
    show info   Show project info
    show types  Show types of all functions
    unlit       Unliterate modules
    build       Compile project
    run         Build and run project
    clean       Clean build files
    prune       Alias for `clean --all`

Options:
    -h, --help  Show this message
    --version   Show version

    -v, --verbose LEVEL  Set verbosity level [default: warn]
" # TODO: Use DocOpt to parse options

begin
  case ARGV.first?
  when "help"
    puts USAGE
  when "init"
    Project.init
  else
    # For other options we need to be in a project directory
    prj = Project.new

    case cmd = ARGV.pop?
    when "show"
      case ARGV.pop?
      when "info"
        prj.show_info
      when "types"
        prj.show_types
      else
        prj.show_info # NOTE: alias for `show info`
      end
    when "unlit"
      prj.unlit
    when "build"
      prj.build
    when "run"
      prj.run
    when "clean"
      prj.clean
    when "prune"
      prj.prune
    when nil
      puts USAGE
    else
      log.fatal(String::Builder.new << cmd.quote << "is not a valid command, run `cl help` to see a list of all available commands")
    end
  end
rescue exc
  log.fatal(String::Builder.new << "Fatal error occured: " << exc)
end

OPTIONS = {} of Symbol => String | Int32 | Bool

OptionParser.parse! do |parser|
  parser.on("-h", "--help", "Show this message") do
    puts USAGE
  end
  parser.on("-v LEVEL", "--verbose LEVEL", "Set verbosity level [default: warn]") do |level|
    OPTIONS[:verbose] = level
  end
end

puts OPTIONS
