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
