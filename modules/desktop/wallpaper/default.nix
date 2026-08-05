# The wallpaper library: the photos under ./photos, and which one is chosen.
#
# It knows nothing about compositors. It resolves the choice to a usable image and publishes it as
# `my.user.desktop.wallpaper.path`; whatever draws backgrounds reads that. modules/desktop/sway.nix
# is the only reader today, through its own `background` option.
#
# webp -- and only webp -- is decoded at build time. gdk-pixbuf, which swaybg and most other viewers
# read through, carries the stock loaders plus librsvg but no webp-pixbuf-loader, so a `.webp` handed
# over as-is leaves the background undrawn with nothing in the log to explain it. PNG, JPEG and SVG
# go to the store untouched. Keeping webp sources also costs git ~216K a photo rather than ~2.5M.
#
# ./photos is read at EVALUATION time, off the flake source -- so a new photo must be `git add`ed
# before it exists as far as this feature is concerned. `import-tree` only loads `.nix`, so the
# folder is invisible to the registry and needs no `_` prefix.
{
    home =
        {
            pkgs,
            lib,
            config,
            tools,
            ...
        }:
        let
            cfg = config.my.user.desktop.wallpaper;

            # `attrNames` sorts, so "the first photo" is a stable choice rather than whatever order
            # the filesystem happened to hand back.
            photos = lib.attrNames (lib.filterAttrs (_: kind: kind == "regular") (builtins.readDir ./photos));

            decoded =
                name:
                let
                    source = ./photos + "/${name}";
                in
                if lib.hasSuffix ".webp" name then
                    pkgs.runCommand "${lib.removeSuffix ".webp" name}.png" {
                        nativeBuildInputs = [ pkgs.libwebp ];
                    } "dwebp ${source} -o $out"
                else
                    source;
        in
        {
            options.my.user.desktop.wallpaper = {
                enable = tools.opt.mkEnabled "publishing a wallpaper for a desktop session to draw";

                photo = lib.mkOption {
                    # An enum over what is actually in ./photos, so a typo is a type error listing the
                    # real choices instead of a path that silently does not exist. An empty folder
                    # gives `enum [ ]`, which only `null` satisfies -- exactly the intended meaning.
                    type = lib.types.nullOr (lib.types.enum photos);
                    default = if photos == [ ] then null else lib.head photos;
                    defaultText = lib.literalMD "the first photo in `./photos`, or `null` when there are none";
                    description = "Which file under modules/desktop/wallpaper/photos to use, by bare filename. `null` for no wallpaper.";
                };

                path = lib.mkOption {
                    type = lib.types.nullOr lib.types.path;
                    readOnly = true;
                    default = if cfg.enable && cfg.photo != null then decoded cfg.photo else null;
                    defaultText = lib.literalMD "`photo`, decoded if its format needs it";
                    description = "The chosen photo as an image a viewer can open, or `null`. Read this; it cannot be set.";
                };
            };
        };
}
