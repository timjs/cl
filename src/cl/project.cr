class Project
  FILE_NAME        = "Project.yml"
  LEGACY_FILE_NAME = "Project.prj"

  HEADER_PREFIX   = ">> module "
  EXPORTED_PREFIX = ">> "
  INTERNAL_PREFIX = ">  " # NOTE: be aware of the double spaces!!!

  def initialize
    LOG.info("Reading project file")
    @manifest = Manifest.from_yaml File.open(FILE_NAME)
  end

  def self.init
    LOG.info("Initialising new project")
    # FIXME: add `init`
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

    Clm.run(@manifest, "-PABC", "-lat", @manifest.executables.first_value.main)
  end

  def unlit
    LOG.info("Unliterating modules")

    lcl_modules.each do |mod|
      unlit_module(mod)
    end
  end

  def check
    unlit
    LOG.info("Typechecking project")

    # FIXME: add output filter
    Clm.run(@manifest, "-PABC", @manifest.executables.first_value.main)
  end

  def build
    unlit
    LOG.info("Building project")

    if OPTS["--legacy"]
      File.create(LEGACY_FILE_NAME) do |io|
        @manifest.to_legacy(io)
      end
      Process.run("cpm", args: [LEGACY_FILE_NAME], output: true, error: true)
    else
      # FIXME: how to support multiple executables? => Use first executable as default, others can be build when passed as an argument (this is what cabal does)
      Clm.run(@manifest, @manifest.executables.first_value.main, "-o", @manifest.executables.first_key)
    end
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

  private def unlit_module(path)
    lit_path = path
    imp_path = path.sub(".lcl", ".icl")
    def_path = path.sub(".lcl", ".dcl")

    # NOTE: accessing lit_path should be safe if `unlit_module` is *only* called with globbed .lcl files
    lit_time = File.stat(lit_path).mtime
    # NOTE: `begin/rescue` is an expression, we don't need a block function or a macro to write this down nicely
    # NOTE: only `Time`s are comparable to each other, therefore we choose the epoch as the default time to compare to if the file doesn't exist
    imp_time = File.stat(imp_path).mtime rescue Time.epoch(0)
    def_time = File.stat(def_path).mtime rescue Time.epoch(0)

    return if lit_time < imp_time && lit_time < def_time

    LOG.debug(path)

    # NOTE:
    #   Although we get a watterfall of `end`s, this is the way to ensure file closings.
    #   Using `ensure` makes variables nillable, so you can't call `File#close` on them.
    #   Blocks are always inlined, thuse this is exaclty the same as using `File.close` at the end of the block!
    #   There is no need for `defer` or forgetting about it!
    File.open(lit_path) do |lit_file|
      File.create(imp_path) do |imp_file|
        File.create(def_path) do |def_file|
          lit_file.each_line do |line|
            case line
            when .starts_with?(HEADER_PREFIX)
              imp_file << "implementation " << line.lchop(EXPORTED_PREFIX) << NL
              def_file << "definition " << line.lchop(EXPORTED_PREFIX) << NL
            when .starts_with?(EXPORTED_PREFIX)
              imp_file << line.lchop(EXPORTED_PREFIX) << NL
              def_file << line.lchop(EXPORTED_PREFIX) << NL
            when .starts_with?(INTERNAL_PREFIX)
              imp_file << line.lchop(INTERNAL_PREFIX) << NL
              def_file << NL
            else
              imp_file << NL
              def_file << NL
            end
          end
        end
      end
    end
  end

  @icl_modules : Array(String)?
  @dcl_modules : Array(String)?
  @lcl_modules : Array(String)?

  # FIXME: glob for all .icls/.dcls and remove `modules` section from manifest?
  private def icl_modules
    @icl_modules ||=
      @manifest.exposed_modules.each
                               .chain(@manifest.other_modules.each)
                               .chain(@manifest.executables.each_value.map(&.main))
                               .map do |mod|
        File.join @manifest.sourcedir, mod.to_path + ".icl"
      end.to_a
  end

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
