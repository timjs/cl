class Clm
  # MODULE_REGEX = /(([A-Z][A-Za-z]+\.?)+)(\.(?:i|d)cl)/
  MODULE_REGEX      = /(?<mod>([A-Z][A-Za-z]+\.?)+)(?<ext>\.(?:i|d)cl)/
  UNIFICATION_REGEX = /cannot unify demanded type with offered type:\n (?<demanded>.+)\n (?<offered>.+)/
  DERIVED_REGEX     = /derived type conflicts with specified type:\n (?<derived>.+)\n (?<specified>.+)\n/

  def self.run(manifest, extra_args)
    args = build_args(manifest, extra_args)
    LOG.debug(String::Builder.new << "Running clm with " << args)

    io = String::Builder.new
    # NOTE: clm writes errors to stderr and all other messages to stdout
    stat = Process.run("clm", args: args, output: LOG.debug?, error: io)
    put_prettified_output(manifest, io.to_s)
    stat
  end

  private def self.build_args(manifest, extra_args)
    args = Array(String).new(4 + 2*manifest.dependencies.size + extra_args.size)
    args << "-dynamics"
    args << "-ms"
    args << "-I" << manifest.sourcedir
    manifest.dependencies.each do |dep|
      args << "-IL" << dep
    end
    args.concat extra_args
  end

  private def self.put_prettified_output(manifest, str)
    # NOTE: `#gsub`'s yields a string and a match
    str = str.gsub MODULE_REGEX do |_, match|
      # FIXME: errors in library modules are not correctly transformed
      path = File.join(manifest.sourcedir, match["mod"].to_path)
      lcl_path = path + ".lcl"
      if manifest.lcl_files.includes?(lcl_path)
        lcl_path
      else
        path + match["ext"]
      end
    end.gsub UNIFICATION_REGEX do |_, match|
      String.build do |str|
        str << "cannot unify demanded type `" << match["demanded"] << "` with offered type` " << match["offered"] << "`"
      end
    end.gsub DERIVED_REGEX do |_, match|
      String.build do |str|
        str << "derived type `" << match["derived"] << "` conflicts with specified type `" << match["specified"] << "`"
      end
    end
    STDERR.puts str
  end
end
