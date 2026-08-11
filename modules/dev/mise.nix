# mise -- polyglot tool-version manager. Rewrites PATH only inside a directory holding a mise.toml or
# .tool-versions, so the nixpkgs toolchains dev.langs installs stay the default everywhere else. What
# mise DOWNLOADS is prebuilt glibc binaries. Those want an FHS loader, so NixOS needs nix-ld for them.
#
# Not bridged to ./direnv.nix: upstream deprecated the `use mise` function and says not to pair the two
# (https://mise.jdx.dev/direnv.html). Each stays inert where the other is in charge, so their prompt
# hooks never touch the same PATH and the order home-manager emits them in does not matter. Give one
# project both a mise.toml and an .envrc and it starts to -- home-manager leaves direnv's zsh hook at the
# default order, so mise would then need `mkBefore` to keep a nix devshell winning.
{
    home =
        {
            lib,
            config,
            tools,
            ...
        }:
        {
            options.my.user.dev.mise.enable =
                tools.opt.mkRiding config.my.user.dev.enable "mise, the tool-version manager";

            config = lib.mkIf config.my.user.dev.mise.enable {
                programs.mise = {
                    enable = true;

                    enableBashIntegration = true;
                    enableZshIntegration = true;
                    enableFishIntegration = true;

                    globalConfig = {
                        settings = {
                            auto_install = true;
                            color_theme = "catppuccin";

                            status = {
                                show_env = true;
                                show_tools = true;
                            };
                        };
                    };
                };
            };
        };
}
