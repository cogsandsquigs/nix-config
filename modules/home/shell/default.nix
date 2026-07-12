{ tools, ... }: {
  imports = [
    ./shell.nix
    ./prompt.nix
  ];

  options.my.user.shell.enable = tools.opt.mkEnabled "shell (fish/bash/zsh) + prompt + aliases";
}
