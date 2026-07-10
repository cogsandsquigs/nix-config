{ tools, ... }: {
    imports = [
        ./shell.nix
        ./prompt.nix
    ];

    options.my.user.shell.enable = tools.mkEnabled "shell (fish/bash/zsh) + prompt + aliases";
}
