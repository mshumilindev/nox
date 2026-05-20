#!/usr/bin/env bash
# Adds `public` to top-level types in a package Sources tree (idempotent for already-public).
set -euo pipefail
DIR="${1:?Sources directory required}"
find "${DIR}" -name '*.swift' -print0 | while IFS= read -r -d '' f; do
  perl -i -pe '
    s/^(\s*)((?:nonisolated\s+)?)(enum|struct|class|protocol|actor)\s/$1$2public $3 /g
      unless /^\s*(?:public|private|fileprivate|internal|open)\s/;
    s/^(\s*)init\(/$1public init(/g unless /^\s*(?:public|private|fileprivate|internal)\s/;
    s/^(\s*)static func /$1public static func /g unless /^\s*(?:public|private|fileprivate|internal)\s/;
    s/^(\s*)static var /$1public static var /g unless /^\s*(?:public|private|fileprivate|internal)\s/;
    s/^(\s*)static let /$1public static let /g unless /^\s*(?:public|private|fileprivate|internal)\s/;
    s/^(\s*)func /$1public func /g unless /^\s*(?:public|private|fileprivate|internal|override)\s/;
    s/^(\s*)var /$1public var /g unless /^\s*(?:public|private|fileprivate|internal|override)\s/;
    s/^(\s*)let /$1public let /g unless /^\s*(?:public|private|fileprivate|internal)\s/;
  ' "${f}"
done
