# The shell group: this file owns the flag and the values, the files under ./shell/ do the work.
{ tools, ... }: {
    options.my.user.shell = {
        enable = tools.opt.mkEnabled "shell (fish/bash/zsh) + prompt + aliases";

        # Where this flake lives on the host. The shell aliases and the .env loader are its only
        # readers, so it belongs to this feature rather than to a central options file.
        flakeDir = tools.opt.mkStr "/etc/nix" "Absolute path to this flake's checkout on the host.";
    };
}
