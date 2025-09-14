#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
getx [-f] [-n] <PageName>

Generate a GetX page skeleton with correct naming:
  • Accepts: PascalCase, camelCase, snake_case, kebab-case, or with spaces
  • Preserves acronyms in PascalCase (e.g., MyHTTPPage -> MyHTTPPage)

Options:
  -f    Force overwrite existing files
  -n    Dry-run (show actions without writing)
  -h    Show this help

Examples:
  getx ForgotPassword
  getx -f my-http-page
  getx "reset password"
USAGE
}

force_overwrite=false
dry_run=false
while getopts ":fnh" opt; do
  case "$opt" in
    f) force_overwrite=true ;;
    n) dry_run=true ;;
    h) usage; exit 0 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage; exit 1 ;;
  esac
done
shift $((OPTIND -1))

if [ "$#" -lt 1 ]; then
  usage
  exit 1
fi

RAW_NAME="$*"

# ---- Converters (portable, macOS-friendly) ----
to_snake() {
  # Normalize delimiters, split camel/Pascal boundaries, then lower snake_case
  # e.g., "ForgotPassword" -> "forgot_password", "MyHTTPPage" -> "my_http_page"
  echo "$1" \
    | perl -pe 's/[_\-\s]+/_/g; s/([A-Z]+)([A-Z][a-z])/$1_$2/g; s/([a-z0-9])([A-Z])/$1_$2/g; $_=lc' \
    | sed 's/[^a-z0-9_]/_/g; s/__*/_/g; s/^_//; s/_$//'
}

to_pascal() {
  # Build PascalCase directly from raw input while preserving acronyms.
  # Splits on spaces/underscores/hyphens and camel boundaries.
  perl -e '
    use strict; use warnings;
    my $s = join(" ", @ARGV);
    $s =~ s/[_\-\s]+/ /g;                             # unify delimiters
    $s =~ s/([A-Z]+)([A-Z][a-z])/$1 $2/g;             # AAAa -> AAA a
    $s =~ s/([a-z0-9])([A-Z])/$1 $2/g;                # aA -> a A
    my @t = grep { length } split / +/, $s;
    my $out = "";
    for my $w (@t) {
      if ($w =~ /^[A-Z]{2,}$/) {                      # keep acronyms as-is
        $out .= $w;
      } else {
        $w = lc $w;
        $w =~ s/^([a-z])/\U$1/;                       # ucfirst
        $out .= $w;
      }
    }
    print $out;
  ' "$1"
}

FEATURE_SNAKE="$(to_snake "$RAW_NAME")"
FEATURE_PASCAL="$(to_pascal "$RAW_NAME")"

if [ -z "$FEATURE_SNAKE" ] || [ -z "$FEATURE_PASCAL" ]; then
  echo "Error: could not derive names from input '$RAW_NAME'." >&2
  exit 1
fi

DIR="$FEATURE_SNAKE"
FILES=(
  "$DIR/${FEATURE_SNAKE}_binding.dart"
  "$DIR/${FEATURE_SNAKE}_logic.dart"
  "$DIR/${FEATURE_SNAKE}_logic_impl.dart"
  "$DIR/${FEATURE_SNAKE}_state.dart"
  "$DIR/${FEATURE_SNAKE}_view.dart"
)

say() { printf "%b\n" "$*"; }
mk()  { $dry_run || mkdir -p "$1"; say "mkdir -p $1"; }
write_file() {
  local path="$1" content="$2"
  if [ -e "$path" ] && [ "$force_overwrite" = false ]; then
    say "skip (exists): $path"
    return 0
  fi
  $dry_run || printf "%s" "$content" > "$path"
  say "write: $path"
}

# ---- Create structure ----
mk "$DIR"
mk "$DIR/widget"

# ---- Templates ----
BINDING_CONTENT="import 'package:get/get.dart';

import '${FEATURE_SNAKE}_logic.dart';
import '${FEATURE_SNAKE}_logic_impl.dart';

class ${FEATURE_PASCAL}Binding extends Bindings {
  @override
  void dependencies() {
    // Bind interface to implementation
    Get.lazyPut<${FEATURE_PASCAL}Logic>(() => ${FEATURE_PASCAL}LogicImpl());
  }
}
"

LOGIC_CONTENT="import '${FEATURE_SNAKE}_state.dart';

abstract class ${FEATURE_PASCAL}Logic {
  abstract final ${FEATURE_PASCAL}State state;
}
"

LOGIC_IMPL_CONTENT="import 'package:get/get.dart';

import '${FEATURE_SNAKE}_logic.dart';
import '${FEATURE_SNAKE}_state.dart';

class ${FEATURE_PASCAL}LogicImpl extends GetxController implements ${FEATURE_PASCAL}Logic {
  @override
  final ${FEATURE_PASCAL}State state = ${FEATURE_PASCAL}State();

  // Add your lifecycle methods or actions here
  // @override
  // void onInit() { super.onInit(); }
}
"

STATE_CONTENT="import 'package:get/get.dart';

class ${FEATURE_PASCAL}State {
  final RxBool fetchingPageData = false.obs;
}
"

VIEW_CONTENT="import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '${FEATURE_SNAKE}_logic.dart';
import '${FEATURE_SNAKE}_state.dart';

class ${FEATURE_PASCAL}Page extends StatelessWidget {
  static const String route = '/$FEATURE_SNAKE';

  ${FEATURE_PASCAL}Page({super.key});

  final ${FEATURE_PASCAL}Logic logic = Get.find<${FEATURE_PASCAL}Logic>();
  final ${FEATURE_PASCAL}State state = Get.find<${FEATURE_PASCAL}Logic>().state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$FEATURE_PASCAL'),
      ),
      body: Center(
        child: Obx(() => Text(
          state.fetchingPageData.value ? 'Loading $FEATURE_PASCAL...' : '$FEATURE_PASCAL',
        )),
      ),
    );
  }
}
"

# ---- Write files ----
write_file "$DIR/${FEATURE_SNAKE}_binding.dart"     "$BINDING_CONTENT"
write_file "$DIR/${FEATURE_SNAKE}_logic.dart"       "$LOGIC_CONTENT"
write_file "$DIR/${FEATURE_SNAKE}_logic_impl.dart"  "$LOGIC_IMPL_CONTENT"
write_file "$DIR/${FEATURE_SNAKE}_state.dart"       "$STATE_CONTENT"
write_file "$DIR/${FEATURE_SNAKE}_view.dart"        "$VIEW_CONTENT"

# ---- Summary ----
say ""
say "✅ Generated GetX page: ${FEATURE_PASCAL}"
say "📁 Folder: ${DIR}"
say "📄 Files:"
for f in "${FILES[@]}"; do say "   - $f"; done
say ""
say "To use:"
say "  • Route: ${FEATURE_PASCAL}Page.routeName"
say "  • Binding: ${FEATURE_PASCAL}Binding() (attach in your GetPage or before navigation)"
say ""
if ! $dry_run; then
  say "Structure:"
  find "$DIR" -maxdepth 2 -print | sed '1d; s,[^/]*/,  ,g; s,^[ ]*,├─ ,; s,├─ \(.*\)/$,└─ \1/,'
fi

