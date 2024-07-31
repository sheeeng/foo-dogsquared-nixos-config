{ lib, ... }:

{
  options.state =
    let
      directoriesSubmodule = { lib, ... }: {
        options = {
          paths = lib.mkOption {
            type = with lib.types; attrsOf (listOf path);
            description = ''
              A set of directories to share its value to various parts of the
              system.
            '';
            default = { };
            example = {
              ignoreDirectories = [ "/var/log" ];
              ignoreFiles = [ "node_modules" ".gitignore" ".bak" ];
            };
          };
        };
      };
    in lib.mkOption {
      type = lib.types.submodule directoriesSubmodule;
    };
}
