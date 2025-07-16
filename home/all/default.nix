{
    globset,
    pkgs,
    lib,
    ...
}:
{
    imports =
        let
            inherit (lib.filesystem) listFilesRecursive;
            inherit (lib.lists) remove;
            inherit (globset.lib) globs;
            inherit (lib.fileset) toList difference fileFilter;
        in
        # remove ./direnv.nix (listFilesRecursive ./.);
        toList (difference (fileFilter (file: file.hasExt "nix") ./.) ./default.nix);

    home.stateVersion = "25.05"; # Home Manager version
    nixpkgs.config.allowUnfree = true;

    home.packages = with pkgs; [ home-manager ];

}
