#!/usr/bin/env bash
set -euo pipefail

# Usage: find-image.sh <image> [owner]
#   find-image.sh nginx                 -> official / single-name registries
#   find-image.sh hermes-agent          -> bare name: also queries Docker Hub search
#   find-image.sh cert-manager jetstack -> owner-scoped registries
#   find-image.sh jetstack/cert-manager -> namespace/repo, tried per registry
#
# Bare-name lookups for namespaced images (e.g. owner/repo) only work on Docker
# Hub, the sole registry with an anonymous search index. ghcr.io / quay.io /
# gcr.io have no anonymous search: there you MUST supply the owner.
#
# Set DEBUG=1 to print the raw skopeo error for each miss.

image="${1:-}"
owner="${2:-}"
timeout="10s"

if [[ -z "$image" ]]; then
  echo "Usage: $0 <image> [owner]" >&2
  exit 1
fi

if ! command -v skopeo >/dev/null 2>&1; then
  echo "skopeo not found. Install with: apt-get install -y skopeo" >&2
  exit 1
fi

if ! command -v gojq >/dev/null 2>&1; then
  echo "gojq not found." >&2
  exit 1
fi

errfile=$(mktemp)
trap 'rm -f "$errfile"' EXIT

namespaced_hosts=(
  docker.io
  ghcr.io
  quay.io
  gcr.io
  registry.gitlab.com
)

# --- Docker Hub search (only registry with an anonymous search index) ---------
# Prints exact repo-name matches as "HUB docker.io/<ns>/<repo>".
# Returns 0 if at least one match was printed.
docker_hub_search() {
  local term="$1"
  local url="https://index.docker.io/v1/search?q=${term}&n=25"
  local fetch json
  if command -v curl >/dev/null 2>&1; then
    fetch=(curl -fsSL --max-time 10)
  elif command -v wget >/dev/null 2>&1; then
    fetch=(wget -qO- --timeout=10)
  else
    echo "Hub search skipped: neither curl nor wget available." >&2
    return 1
  fi
  json=$("${fetch[@]}" "$url" 2>/dev/null) || { echo "Hub search request failed." >&2; return 1; }

  local matches
  matches=$(printf '%s' "$json" | gojq -r --arg img "$term" '
    .results
    | map(select((.name == $img) or (.name | endswith("/" + $img))))
    | sort_by(.star_count) | reverse
    | .[] | "docker.io/\(.name)\t(stars: \(.star_count))"')

  [[ -z "$matches" ]] && return 1
  printf '%s\n' "$matches" | sed 's/\t/  /; s/^/HUB    /'
  return 0
}

# --- Build direct candidate references ----------------------------------------
candidates=()
hub_search=0
if [[ -n "$owner" ]]; then
  for host in "${namespaced_hosts[@]}"; do
    candidates+=("${host}/${owner}/${image}")
  done
elif [[ "$image" == */* ]]; then
  for host in "${namespaced_hosts[@]}"; do
    candidates+=("${host}/${image}")
  done
else
  candidates+=(
    "docker.io/library/${image}"
    "mcr.microsoft.com/${image}"
    "registry.k8s.io/${image}"
  )
  hub_search=1
fi

# --- Probe direct candidates --------------------------------------------------
found=0
for ref in "${candidates[@]}"; do
  if out=$(skopeo --command-timeout "$timeout" list-tags "docker://${ref}" 2>"$errfile"); then
    if printf '%s' "$out" | grep -Eq '"Tags"[[:space:]]*:[[:space:]]*(\[\]|null)'; then
      [[ "${DEBUG:-}" == "1" ]] && echo "EMPTY  docker://${ref}" >&2
      continue
    fi
    ntags=$(printf '%s' "$out" | gojq -r '.Tags | length')
    printf 'FOUND  docker://%-50s (%s tags)\n' "$ref" "$ntags"
    found=1
  else
    [[ "${DEBUG:-}" == "1" ]] && printf 'MISS   docker://%-50s %s\n' "$ref" "$(tr '\n' ' ' < "$errfile")" >&2
  fi
done

# --- Hub search fallback for bare names ---------------------------------------
if [[ "$hub_search" -eq 1 ]]; then
  if docker_hub_search "$image"; then
    found=1
  fi
fi

if [[ "$found" -eq 0 ]]; then
  echo "Not found in the probed public registries." >&2
  exit 2
fi
