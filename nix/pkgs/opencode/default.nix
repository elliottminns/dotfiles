{
  lib,
  stdenvNoCC,
  bun,
  fetchFromGitHub,
  fzf,
  makeBinaryWrapper,
  models-dev,
  ripgrep,
  installShellFiles,
  writableTmpDirAsHomeHook,
}:
let
  pname = "opencode";
  version = "1.1.12";
  src = fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${version}";
    hash = "sha256-k6wRBtWFwyLWJ6R0el3dY/nBlg2t+XkTpsuEseLXp+E=";
  };

  node_modules = stdenvNoCC.mkDerivation {
    pname = "${pname}-node_modules";
    inherit version src;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)

      bun install \
        --cpu="*" \
        --filter=./packages/opencode \
        --force \
        --frozen-lockfile \
        --ignore-scripts \
        --no-progress \
        --os="*" \
        --production

      bun run ./nix/scripts/canonicalize-node-modules.ts
      bun run ./nix/scripts/normalize-bun-binaries.ts

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      find . -type d -name node_modules -exec cp -R --parents {} $out \;

      runHook postInstall
    '';

    dontFixup = true;

    outputHash = "sha256-vRIWQt02VljcoYG3mwJy8uCihSTB/OLypyw+vt8LuL8=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  inherit
    pname
    version
    src
    node_modules
    ;

  nativeBuildInputs = [
    bun
    installShellFiles
    makeBinaryWrapper
    models-dev
    writableTmpDirAsHomeHook
  ];

  dontConfigure = true;

  env.MODELS_DEV_API_JSON = "${models-dev}/dist/_api.json";
  env.OPENCODE_VERSION = finalAttrs.version;
  env.OPENCODE_CHANNEL = "stable";

  buildPhase = ''
    runHook preBuild

    cp -r ${finalAttrs.node_modules}/node_modules .
    cp -r ${finalAttrs.node_modules}/packages .

    (
      cd packages/opencode

      chmod -R u+w ./node_modules
      mkdir -p ./node_modules/@opencode-ai
      rm -f ./node_modules/@opencode-ai/{script,sdk,plugin}
      ln -s $(pwd)/../../packages/script ./node_modules/@opencode-ai/script
      ln -s $(pwd)/../../packages/sdk/js ./node_modules/@opencode-ai/sdk
      ln -s $(pwd)/../../packages/plugin ./node_modules/@opencode-ai/plugin

      cp ../../nix/bundle.ts ./bundle.ts
      chmod +x ./bundle.ts
      bun run ./bundle.ts
    )

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cd packages/opencode
    if [ ! -d dist ]; then
      echo "ERROR: dist directory missing after bundle step"
      exit 1
    fi

    mkdir -p $out/lib/opencode
    cp -r dist $out/lib/opencode/
    chmod -R u+w $out/lib/opencode/dist

    worker_file=$(find "$out/lib/opencode/dist" -type f \( -path '*/tui/worker.*' -o -name 'worker.*' \) | sort | head -n1)
    parser_worker_file=$(find "$out/lib/opencode/dist" -type f -name 'parser.worker.*' | sort | head -n1)
    if [ -z "$worker_file" ]; then
      echo "ERROR: bundled worker not found"
      exit 1
    fi

    main_wasm=$(printf '%s\n' "$out"/lib/opencode/dist/tree-sitter-*.wasm | sort | head -n1)
    wasm_list=$(find "$out/lib/opencode/dist" -maxdepth 1 -name 'tree-sitter-*.wasm' -print)
    for patch_file in "$worker_file" "$parser_worker_file"; do
      [ -z "$patch_file" ] && continue
      [ ! -f "$patch_file" ] && continue
      if [ -n "$wasm_list" ] && grep -q 'tree-sitter' "$patch_file"; then
        bun --bun ../../nix/scripts/patch-wasm.ts "$patch_file" "$main_wasm" $wasm_list
      fi
    done

    mkdir -p $out/lib/opencode/node_modules
    cp -r ../../node_modules/.bun $out/lib/opencode/node_modules/
    mkdir -p $out/lib/opencode/node_modules/@opentui

    mkdir -p $out/share/opencode
    HOME=$TMPDIR bun --bun script/schema.ts $out/share/opencode/schema.json

    mkdir -p $out/bin
    makeWrapper ${lib.getExe bun} $out/bin/opencode \
      --add-flags "run" \
      --add-flags "$out/lib/opencode/dist/src/index.js" \
      --prefix PATH : ${
        lib.makeBinPath [
          fzf
          ripgrep
        ]
      } \
      --argv0 opencode

    runHook postInstall
  '';

  postInstall = ''
    pkgs=(
      $out/lib/opencode/node_modules/.bun/@opentui+core-*
      $out/lib/opencode/node_modules/.bun/@opentui+solid-*
      $out/lib/opencode/node_modules/.bun/@opentui+core@*
      $out/lib/opencode/node_modules/.bun/@opentui+solid@*
    )
    for pkg in "''${pkgs[@]}"; do
      if [ -d "$pkg" ]; then
        pkgName=$(basename "$pkg" | sed 's/@opentui+\([^@]*\)@.*/\1/')
        ln -sf ../.bun/$(basename "$pkg")/node_modules/@opentui/$pkgName \
          $out/lib/opencode/node_modules/@opentui/$pkgName
      fi
    done

    ${lib.optionalString
      (
        (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform)
        && (stdenvNoCC.hostPlatform.system != "x86_64-darwin")
      )
      ''
        installShellCompletion --cmd opencode \
          --bash <($out/bin/opencode completion)
      ''
    }
  '';

  meta = {
    description = "AI coding agent built for the terminal";
    homepage = "https://github.com/anomalyco/opencode";
    license = lib.licenses.mit;
    mainProgram = "opencode";
  };
})
