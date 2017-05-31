# cl

A simple, no-nonsense Clean project manager

## Installation

You need [Crylstal](https://crystal-lang.org) to build this project.
Below some simple instructions for macOS.
Other Unixes should be supported too.

### macOS

```shell
> brew install crystal-lang
> git clone https://github.com/timjs/cl.git
> cd cl
> crystal build --release src/cl.cr
> cp cl ~/local/bin # or your directory of choice
```

## Usage

```shell
> cl help
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
    prune       Prune artifacts and build files

Options:
    -h, --help           Show this message
    --legacy             Use legacy build system
    -v, --verbose LEVEL  Set verbosity level [default: warn]
    --version            Show version
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it ( https://github.com/timjs/cl/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [timjs](https://github.com/timjs) Tim Steenvoorden - creator, maintainer
