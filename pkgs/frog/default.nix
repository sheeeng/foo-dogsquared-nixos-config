{ stdenv
, lib
, fetchFromGitHub
, python3Packages
, wrapGAppsHook4
, gtk4
, meson
, ninja
, pkg-config
, appstream-glib
, desktop-file-utils
, glib
, gobject-introspection
, libnotify
, libadwaita
, libportal
, gettext
, librsvg
, tesseract5
, zbar
}:

python3Packages.buildPythonApplication rec {
  pname = "frog";
  version = "1.1.3";

  src = fetchFromGitHub {
    owner = "TenderOwl";
    repo = "Frog";
    rev = version;
    sha256 = "sha256-yOjfiGJUU25zb/4WprPU59yDAMpttS3jREp1kB5mXUE=";
  };

  format = "other";

  patches = [ ./patches/update-compatible-with-non-flatpak-env.patch ];
  postPatch = ''
    chmod +x ./build-aux/meson/postinstall.py
    patchShebangs ./build-aux/meson/postinstall.py
    substituteInPlace ./build-aux/meson/postinstall.py \
      --replace "gtk-update-icon-cache" "gtk4-update-icon-cache"
    substituteInPlace ./frog/language_manager.py --subst-var out
  '';

  nativeBuildInputs = [
    appstream-glib
    desktop-file-utils
    gettext
    meson
    ninja
    pkg-config
    glib
    wrapGAppsHook4
  ];

  buildInputs = [
    librsvg
    gobject-introspection
    libnotify
    libadwaita
    libportal
    zbar
    tesseract5
  ];

  propagatedBuildInputs = with python3Packages; [
    pygobject3
    pillow
    pytesseract
    pyzbar
  ];

  dontWrapGApps = true;
  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  meta = with lib; {
    homepage = "https://getfrog.app/";
    description =
      "Intuitive optical character recognition (OCR) for GNOME desktop";
    license = licenses.mit;
  };
}
