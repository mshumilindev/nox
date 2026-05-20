#!/usr/bin/env bash
# Adds public to member declarations inside public types in a package Sources tree.
set -euo pipefail
ROOT="${1:?Package Sources dir}"
find "${ROOT}" -name '*.swift' | while read -r f; do
  perl -i -0pe '
    s/((?:nonisolated )?public enum [^\{]*\{)(.*?)(\n\})/ 
      my ($h,$b,$e)=($1,$2,$3);
      $b =~ s/^(\s+)(?!(?:public|private|fileprivate|internal|open|@|#)\b)(static let |static var |static func |var |func )/$1public $2/gm;
      "$h$b$e"
    /gse;
    s/((?:nonisolated )?public (?:struct|class|protocol|actor)[^\{]*\{)(.*?)(\n\})/ 
      my ($h,$b,$e)=($1,$2,$3);
      $b =~ s/^(\s+)(?!(?:public|private|fileprivate|internal|open|@)\b)(let |var |func |init\()/$1public $2/gm;
      "$h$b$e"
    /gse' "${f}" 2>/dev/null || true
done
