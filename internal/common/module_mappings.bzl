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

# Definitions for handling path re-mapping, to support short module names.
# See pathMapping doc: https://github.com/Microsoft/TypeScript/issues/5039
#
# This reads the module_root and module_name attributes from typescript rules in
# the transitive closure, rolling these up to provide a mapping to the
# TypeScript compiler and to editors.
#

def _get_deps(attrs, names):
  return [d for n in names if hasattr(attrs, n)
          for d in getattr(attrs, n)]

# Traverse 'srcs' in addition so that we can go across a genrule
_MODULE_MAPPINGS_DEPS_NAMES = (["deps", "srcs"]
)

_DEBUG = False

def debug(msg, values=()):
  if _DEBUG:
    print(msg % values)

def get_module_mappings(label, attrs, srcs = []):
  """Returns the module_mappings from the given attrs.

  Collects a {module_name - module_root} hash from all transitive dependencies,
  checking for collisions. If a module has a non-empty `module_root` attribute,
  all sources underneath it are treated as if they were rooted at a folder
  `module_name`.
  """
  mappings = dict()
  all_deps =  _get_deps(attrs, names = _MODULE_MAPPINGS_DEPS_NAMES)
  for dep in all_deps:
    if not hasattr(dep, "es6_module_mappings"):
      continue
    for k, v in dep.es6_module_mappings.items():
      if k in mappings and mappings[k] != v:
        fail(("duplicate module mapping at %s: %s maps to both %s and %s" %
              (label, k, mappings[k], v)), "deps")
      mappings[k] = v
  if ((hasattr(attrs, "module_name") and attrs.module_name) or
      (hasattr(attrs, "module_root") and attrs.module_root)):
    mn = attrs.module_name
    if not mn:
      mn = label.name
    mr = label.package
    if attrs.module_root and attrs.module_root != ".":
      mr = "%s/%s" % (mr, attrs.module_root)
      # Validate that sources are underneath the module root.
      # module_roots ending in .ts are a special case, they are used to
      # restrict what's exported from a build rule, e.g. only exports from a
      # specific index.d.ts file. For those, not every source must be under the
      # given module root.
      if not attrs.module_root.endswith(".ts"):
        for s in srcs:
          if not s.short_path.startswith(mr):
            fail(("all sources must be under module root: %s, but found: %s" %
                  (mr, s.short_path)))
    if mn in mappings and mappings[mn] != mr:
      fail(("duplicate module mapping at %s: %s maps to both %s and %s" %
            (label, mn, mappings[mn], mr)), "deps")
    mappings[mn] = mr
  debug("Mappings at %s: %s", (label, mappings))
  return mappings

def _module_mappings_aspect_impl(target, ctx):
  mappings = get_module_mappings(target.label, ctx.rule.attr)
  return struct(es6_module_mappings = mappings)

module_mappings_aspect = aspect(
    _module_mappings_aspect_impl,
    attr_aspects = _MODULE_MAPPINGS_DEPS_NAMES,
)
