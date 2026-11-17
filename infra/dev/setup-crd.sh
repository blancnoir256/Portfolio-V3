if [[ $# -gt 1 ]]; then
  printf 'Usage: setup-crd [manifest-directory]\n' >&2
  exit 2
fi

manifest_dir="${1:-.}"
if [[ ! -f "$manifest_dir/kustomization.yaml" && ! -f "$manifest_dir/kustomization.yml" && ! -f "$manifest_dir/Kustomization" ]]; then
  printf 'No Kustomization found in %s\n' "$manifest_dir" >&2
  exit 1
fi

mkdir -p -- "$manifest_dir/.crd"
install -m 0644 -- "$CRD_SCHEMAS"/*.json "$manifest_dir/.crd/"
printf 'CRD schemas installed in %s/.crd\n' "$manifest_dir"
