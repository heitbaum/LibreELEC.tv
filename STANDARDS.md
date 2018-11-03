## Project Coding Standards

### Build system scripts and config:

* All LibreELEC build system scripts are bash scripts (`/bin/bash`)
* Avoid backticks. Use `$()` instead
* String comparison: use `=` not `==`
* Numeric comparison: use `-eq` not `=` etc.
* Use `[ test 1 -o test2 ]/[ test1 -a test2 ]` rather than `[[ test1 ]] || [[ test2 ]]`/`[[ test1 ]] && [[ test2 ]]` etc. See [test constructs](https://www.tldp.org/LDP/abs/html/testconstructs.html)
* Shell variables do not use braces ie. use `$FOO` unless braces are required (string substitution etc.)
* Use double-quotes (") around variables (or sequences that include variables) when possible to avoid issues with special characters, eg. `cd "$PKG_DIR/scripts"`. See [quoting variables](https://www.tldp.org/LDP/abs/html/quotingvar.html)
* Use `. config/blah` to source a file, don't use `source config/blah`
* To be efficient, avoid forking child processes (`sed`, `cut`, etc.) when a shell built-in can be used instead
* Avoid long lines (> 90 columns) unless it aids maintainability/processing (eg. `LINUX_DEPENDS`, `PKG_DEPENDS_TARGET` etc.)
* Indent using 2 spaces within comments:
```
# include helper functions
  . config/functions

# include versioning
  . config/version
```

### Within `package.mk`:

* See [packages/readme.md](packages/readme.md) for more detailed package structure information
* When using git revisions, the full 40-char revision is to be used
* Prefix package specific variables with `PKG_` as they are automatically unset before `package.mk` is sourced
* When creating a directory, related lines are indented:
```
  cd $INSTALL/blah
    cp -P foo $INSTALL/blah
```
