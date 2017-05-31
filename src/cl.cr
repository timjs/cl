require "logger"
require "colorize"
require "docopt"

require "./cl/*"

# Options ######################################################################

VERSION = "0.4.0"
USAGE   = "\
Clean command line tools

Usage:
    cl <command> [options] [<arguments>...]

Commands:
    help        Show this message
    init        Initialise new project
    show info   Show project info
    show types  Show types of all functions
    check       Typecheck modules
    unlit       Unliterate modules
    build       Compile project
    run         Build and run project
    clean       Clean build files
    prune       Alias for `clean --all`

Options:
    -h, --help           Show this message
    --legacy             Use legacy build system
    -v, --verbose LEVEL  Set verbosity level [default: warn]
    --version            Show version
"

OPTS = Docopt.docopt(USAGE, version: VERSION)
ARGS = OPTS["<arguments>"].as(Array(String))

# Logging ######################################################################

# NOTE: Should be constant, otherwise it is not visible inside classes
LOG = Logger.new(STDERR)
LOG.level = Logger::Severity.from_s(OPTS["--verbose"].as(String))
LOG.formatter = Logger::Formatter.new do |severity, _datetime, _progname, message, io|
  io << case severity # FIXME: change to enum values in next version
  when "DEBUG"
    ":: ".colorize.white
  when "INFO"
    ">> ".colorize.green
  when "WARN"
    "** ".colorize.yellow
  when "ERROR", "FATAL"
    "!! ".colorize.red
  end
  io << message
  io << "..." if severity == "INFO"
end

# Main #########################################################################

LOG.debug(OPTS.inspect)

begin
  case cmd = OPTS["<command>"].as(String)
  when "help"
    puts USAGE
  when "init"
    Project.init
  else
    # For other options we need to be in a project directory
    prj = Project.new

    case cmd
    when "show"
      case subcmd = ARGS.shift?
      when "info", nil
        prj.show_info
      when "types"
        prj.show_types
      else
        LOG.fatal(String::Builder.new << subcmd.quote << "is not a valid subcommand of `show`, run `cl help` to see a list of all available commands")
        exit 1
      end
    when "check"
      prj.check
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
    else
      LOG.fatal(String::Builder.new << cmd.quote << "is not a valid command, run `cl help` to see a list of all available commands")
      exit 1
    end
  end
rescue exc
  LOG.fatal(String::Builder.new << exc << " (" << exc.class << ")")
  exit 1
end
