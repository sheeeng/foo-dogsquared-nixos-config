# My custom shell for developing Flatpak manifests.
# This is not suitable outside of NixOS, unfortunately.
{ mkShell
, lib
, diffoscope
, flatpak-builder
, editorconfig-checker
, editorconfig-core-c
, git
, dasel
}:

mkShell {
  packages = [
    dasel # For converting various data into something.
    diffoscope # `diff(1)` on steroids.
    flatpak-builder # A required tool.
    editorconfig-checker # We're most likely writing manifests in YAML so I need them consistent spaces.
    editorconfig-core-c # editorconfig will not work without the engine, of course.
    git # This is the common choice as the VCS — otherwise, bring your own.
  ];
}
