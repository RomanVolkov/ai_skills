#!/bin/bash
# output the absolute path to the skill directory
# this allows scripts to find the skill root regardless of working directory
#
# usage: SKILL_DIR=$(bash path/to/get-skill-dir.sh)
# or:    source get-skill-dir.sh && SKILL_DIR="$SKILL_DIR"

set -e

# derive skill root from script location
# script is at <skill-root>/scripts/get-skill-dir.sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"

echo "$SKILL_ROOT"
