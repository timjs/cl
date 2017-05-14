require "YAML"

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
