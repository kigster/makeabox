workspace(name = "my_ruby_project")


load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

#———————————————————————————————————————————————————————————————————————
# To get the latest ruby rules, grab the 'develop' branch.
#———————————————————————————————————————————————————————————————————————

git_repository(
    name = "bazelruby_rules_ruby",
    remote = "https://github.com/bazelruby/rules_ruby.git",
    branch = "develop",
)

load(
    "@bazelruby_rules_ruby//ruby:deps.bzl",
    "rules_ruby_dependencies",
    "rules_ruby_select_sdk",
)

rules_ruby_dependencies()

#load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")
#bazel_skylib_workspace()

#———————————————————————————————————————————————————————————————————————
# Specify Ruby version — this will either build Ruby or use a local
# RBENV installation if the Ruby version matches.
#———————————————————————————————————————————————————————————————————————

rules_ruby_select_sdk(version = "2.7.0")

#———————————————————————————————————————————————————————————————————————
# Now, load the ruby_bundle rule & install gems specified in the Gemfile
#———————————————————————————————————————————————————————————————————————

load(
    "@bazelruby_rules_ruby//ruby:defs.bzl", 
    "ruby_bundle",
)

ruby_bundle(
    name = "bundle",
    excludes = {
        "mini_portile": ["test/**/*"],
    },
    gemfile = "//:Gemfile",
    gemfile_lock = "//:Gemfile.lock",
)
