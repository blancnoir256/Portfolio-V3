{
  fetchurl,
  python3,
  runCommand,
}:

let
  traefikVersion = "3.6.25";
  definitions = fetchurl {
    url = "https://raw.githubusercontent.com/traefik/traefik/v${traefikVersion}/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml";
    hash = "sha256-3wPpqPPmYV51T131MnAMESHCiSoli0YdOlXo716c9Yk=";
  };
  converter = fetchurl {
    url = "https://raw.githubusercontent.com/yannh/kubeconform/v0.8.0/scripts/openapi2jsonschema.py";
    hash = "sha256-0UW6v7t2UAQDB2ThtOUYv7ekvX8RFpGgj6V5g7gYgfM=";
  };
  python = python3.withPackages (ps: [ ps.pyyaml ]);
in
runCommand "traefik-crd-schemas-${traefikVersion}" {
  nativeBuildInputs = [ python ];
} ''
  mkdir -p "$out"
  cd "$out"
  export FILENAME_FORMAT='{fullgroup}-{kind}-{version}'
  python3 ${converter} ${definitions}

  python3 - <<'PY'
  import json
  from pathlib import Path

  schemas = list(Path.cwd().glob("*.json"))
  assert schemas, "No CRD schemas were generated"
  for path in schemas:
      schema = json.loads(path.read_text())
      assert schema["type"] == "object", f"Invalid root schema: {path.name}"

  ingressroute = json.loads(Path("traefik.io-ingressroute-v1alpha1.json").read_text())
  properties = ingressroute["properties"]["spec"]["properties"]
  assert {"entryPoints", "routes", "tls"} <= properties.keys()
  assert properties["routes"]["type"] == "array"
  assert "services" in properties["routes"]["items"]["properties"]
  PY
''
