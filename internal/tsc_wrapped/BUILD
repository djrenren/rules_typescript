# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("//:defs.bzl", "ts_library")
load("//internal:node.bzl", "nodejs_binary")

# Vanilla typescript compiler: run the tsc.js binary distributed by TypeScript
nodejs_binary(
    name = "tsc",
    data = ["@npm//installed:node_modules"],
    main = "npm/installed/node_modules/typescript/lib/tsc.js",
)

# Build our custom compiler using the vanilla one
ts_library(
  name = "tsc_wrapped",
  srcs = glob(["*.ts"], exclude = ["*_test.ts"]),
  tsconfig = ":tsconfig.json",
  tsc = ":tsc",
)

# Other ts_library rules will use this custom compiler, which calls the
# TypeScript APIs to act like tsc, but adds capabilities like Bazel workers.
nodejs_binary(
    name = "tsc_wrapped_bin",
    data = [
      ":tsc_wrapped",
      "@npm//installed:node_modules",
    ],
    main = "io_bazel_rules_typescript/internal/tsc_wrapped/tsc_wrapped.js",
    visibility = ["//visibility:public"],
)
