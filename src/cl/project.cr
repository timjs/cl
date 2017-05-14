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

    # FIXME: glob over .icl files would be fine...
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
