load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_rust",
    integrity = "sha256-GuRaQT0LlDOYcyDfKtQQ22oV+vtsiM8P0b87qsvoJts=",
    urls = ["https://github.com/bazelbuild/rules_rust/releases/download/0.39.0/rules_rust-v0.39.0.tar.gz"],
)

load("@rules_rust//rust:repositories.bzl", "rules_rust_dependencies", "rust_register_toolchains")

rules_rust_dependencies()

rust_register_toolchains()

load("@rules_rust//crate_universe:defs.bzl", "crates_repository")

crates_repository(
    name = "cli_crates",
    cargo_lockfile = "//cli:Cargo.lock",
    lockfile = "//cli:Cargo.Bazel.lock",
    manifests = ["//cli:Cargo.toml"],
)

load("@cli_crates//:defs.bzl", cli_crate_repositories = "crate_repositories")

cli_crate_repositories()