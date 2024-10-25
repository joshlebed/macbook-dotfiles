#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.mode compact

# @raycast.title PR
# @raycast.icon ↗️
# @raycast.packageName open gentrace repo in vscode
# @raycast.argument1 { "type": "text", "placeholder": "PR number" }

open "https://github.com/gentrace/gentrace/pull/"$1
