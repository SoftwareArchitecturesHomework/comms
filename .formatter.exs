[
  import_deps: [:phoenix],
  subdirectories: ["priv/*/migrations"],
  inputs: ["*.{heex,eex,ex,exs}", "{config,lib,test}/**/*.{heex,eex,ex,exs}", "priv/*/seeds.exs"]
]
