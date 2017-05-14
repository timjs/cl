require "logger"
require "colorize"
require "option_parser"
require "YAML"

# Exceptions ###################################################################

class Unimplemented < Exception
end

# Logger #######################################################################

# NOTE: Should be constant, otherwise it is not visible inside classes
LOG = Logger.new(STDERR)
LOG.level = Logger::DEBUG
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

  def to_path
    gsub('.', File::SEPARATOR)
  end

  def from_path
    gsub(File::SEPARATOR, '.')
  end
end

# Clm ##########################################################################

class Clm < Process
  def self.run(manifest, *extras)
    args = Array(String).new(4 + 2*manifest.dependencies.size + extras.size)
    args << "-dynamics"
    args << "-ms"
    args << "-I" << manifest.sourcedir
    manifest.dependencies.each do |dep|
      args << "-IL" << dep
    end
    args.push *extras

    LOG.debug(String::Builder.new << "Running clm with " << args)
    super("clm", args: args, output: true, error: true)
  end
end

# Manifest #####################################################################

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
  #     exposed_modules: Array(String),
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

# Project ######################################################################
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
    @manifest.to_yaml(STDOUT)
  end

  def show_types
    unlit
    LOG.info("Collecting types of functions")

    icl_modules.each do |path|
      File.touch path
    end

    # FIXME: how to support multiple executables?
    Clm.run(@manifest, "-PABC", "-lat", @manifest.executables.first_value.main)
  end

  def unlit
  end

  def check
    unlit
    LOG.info("Typechecking project")

    # FIXME: how to support multiple executables?
    # FIXME: add output filter
    Clm.run(@manifest, "-PABC", @manifest.executables.first_value.main)
  end

  def build
    unlit
    LOG.info("Building project")

    Clm.run(@manifest, @manifest.executables.first_value.main, "-o", @manifest.executables.first_key)
  end

  def run
    build
    LOG.info("Running project")

    Process.run("./" + @manifest.executables.first_key)
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

    # NOTE: can't splat an array because size is unknown at compile time, therefore we push args to the created `keys` array
    Dir.glob(@manifest.executables.keys << LEGACY_FILE_NAME << "*-data") do |pat|
      File.delete(pat)
    end
  end

  @icl_modules : Array(String)?
  @dcl_modules : Array(String)?
  @lcl_modules : Array(String)?

  # FIXME: glob for all icls and remove `modules` section from manifest?
  private def icl_modules
    @icl_modules ||=
      @manifest.exposed_modules.each
                               .chain(@manifest.other_modules.each)
                               .chain(@manifest.executables.each_value.map(&.main))
                               .map do |mod|
        File.join @manifest.sourcedir, mod.to_path + ".icl"
      end.to_a
  end
  # FIXME: glob for all dcls and remove `modules` section from manifest?
  private def dcl_modules
    @dcl_modules ||=
      @manifest.exposed_modules.each
                               .chain(@manifest.other_modules.each)
                               .map do |mod|
        File.join @manifest.sourcedir, mod.to_path + ".dcl"
      end.to_a
  end
  private def lcl_modules
    @lcl_modules ||= Dir.glob("**/*.lcl")
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

    case cmd = ARGV.shift?
    when "show"
      case ARGV.shift?
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
  LOG.fatal(String::Builder.new << exc << " (" << exc.class << ")")
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
