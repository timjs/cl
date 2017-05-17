require "YAML"
require "ecr/macros"

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

  LEGACY_TEMPLATE_NAME = "src/cl/legacy_project.ecr"

  def to_legacy(io)
    ECR.embed(LEGACY_TEMPLATE_NAME, io)
  end

  # FIXME: place to be?
  def icl_files
    @icl_files ||= Dir.glob("**/*.icl")
  end

  def dcl_files
    @dcl_files ||= Dir.glob("**/*.dcl")
  end

  def lcl_files
    @lcl_files ||= Dir.glob("**/*.lcl")
  end
end
