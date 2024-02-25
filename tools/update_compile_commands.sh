#!/usr/bin/env bash

BAZEL="$(which bazel || which bazelisk)"
exec "${BAZEL}" run @hedron_compile_commands//:refresh_all