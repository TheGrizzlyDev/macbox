#!/usr/bin/env bash

BAZEL="$(which bazel || which bazelisk)"
exec "${BAZEL}" run //tools:gopackagesdriver -- "${@}"
