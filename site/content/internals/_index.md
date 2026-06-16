+++
title = "Internals"
sort_by = "weight"
weight = 5
template = "section.html"
description = "Storage layout, the dvs.toml file, the audit log, and the error surface."
+++

Implementation detail, beyond what normal use requires. None of it is needed to
run the four verbs; the [R Package](@/r-package/_index.md) and
[CLI](@/cli/_index.md) sections cover everyday use.

These pages describe how dvs works underneath: how files are stored and
addressed, the `dvs.toml` project file, the append-only audit log, and the
errors dvs can raise.
