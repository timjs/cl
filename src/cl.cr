require "logger"
require "colorize"
require "option_parser"
require "YAML"

# Constants ####################################################################

LEGACY_PROJECT_FILE_NAME = "Project.prj"

# Exceptions ###################################################################

class Unimplemented < Exception
end

# Logger #######################################################################

# NOTE: Should be constant, otherwise it is not visible inside classes
LOG = Logger.new(STDERR)
LOG.level = Logger::INFO
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

# Extensions ###################################################################

class String
  def quote
    String.build(self.bytesize + 2) do |str|
      str << "`" << self << "`"
    end
  end
end

# Project ######################################################################

class Manifest
  YAML.mapping({
    # Metadata
    name: {
      type: String,
    },
    version: {
      type: String,
    },
    authors: {
      type: Array(String),
    },
    # Project
    sourcedir: {
      type:    String,
      default: "src",
    },
    exposed_modules: {
      key:     "modules",
      type:    Array(String),
      default: [] of String,
    },
    other_modules: {
      key:     "other-modules",
      type:    Array(String),
      default: [] of String,
    },
    dependencies: {
      type:    Array(String), # Hash(String, DependencyInfo),
      default: ["Dynamics", "Generics", "Platform"],
    },
    # Targets
    executables: {
      type:    Hash(String, ExecutableInfo),
      default: {} of String => ExecutableInfo,
    },
    # libraries: Hash(String, LibraryInfo),
  })

  class ExecutableInfo
    YAML.mapping({
      main: {
        type:    String,
        default: "Main",
      },
    })

    def self.default
      ExecutableInfo.new(main: "Main")
    end

    def initialize(@main)
    end
  end

  # class LibraryInfo
  #   YAML.mapping(
  #     modules: Array(String),
  #     other_modules: Array(String),
  #   )
  # end
  #
  # class DependencyInfo
  #   YAML.mapping(
  #     version: String?,
  #     path: String?,
  #     git: String?,
  #   )
  # end

end

class Project
  FILE_NAME        = "Project.yml"
  LEGACY_FILE_NAME = "Project.prj"

  def initialize
    LOG.info("Reading project file")
    @manifest = Manifest.from_yaml File.open(FILE_NAME)
  end

  def self.init
    LOG.info("Initialising new project")
    raise Unimplemented.new
  end

  def show_info
    LOG.info("Showing information about current project")
    puts @manifest.to_yaml
  end

  def show_types
    unlit

    LOG.info("Collecting types of functions")

    icl_modules.each do |path|
      File.touch path
    end
  end

  def unlit
  end

  def check
  end

  def build
  end

  def run
  end

  def clean
    LOG.info("Cleaning files")

    Dir.glob("**/Clean System Files/", "*-sapl", "*-www") do |pat|
      LOG.debug(pat)
      File.delete(pat)
    end
  end

  def prune
    clean
    LOG.info("Pruning files")

    Dir.glob( # manifest.executable.name,
LEGACY_PROJECT_FILE_NAME, "*-data") do |pat|
      File.delete(pat)
    end
  end

  @icl_modules : Array(String)?
  @dcl_modules : Array(String)?

  private def icl_modules
    @icl_modules ||= @manifest.exposed_modules.each.chain(@manifest.other_modules.each).map do |mod|
      mod.gsub(".", File::SEPARATOR) + ".icl"
    end.to_a
  end
  private def dcl_modules
    @dcl_modules ||= @manifest.exposed_modules.each.chain(@manifest.other_modules.each).map do |mod|
      mod.gsub(".", File::SEPARATOR) + ".dcl"
    end.to_a
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
    check       Typecheck modules
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
    when nil
      puts USAGE
    else
      LOG.fatal(String::Builder.new << cmd.quote << "is not a valid command, run `cl help` to see a list of all available commands")
    end
  end
rescue exc
  LOG.fatal(String::Builder.new << "Fatal error occured: " << exc << " (" << exc.class << ")")
end

# OPTIONS = {} of Symbol => String | Int32 | Bool
# OptionParser.parse! do |parser|
#   parser.on("-h", "--help", "Show this message") do
#     puts USAGE
#   end
#   parser.on("-v LEVEL", "--verbose LEVEL", "Set verbosity level [default: warn]") do |level|
#     OPTIONS[:verbose] = level
#   end
# end
# puts OPTIONS
