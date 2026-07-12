# Editors under the dev group. helix is the daily editor (rides the dev master → on wherever dev
# is). vscode is opt-in (off everywhere by default) and ships install-only — a unit turns it on
# with `my.user.dev.editors.vscode.enable = true` (e.g. the work box) without polluting others.
{ config, tools, ... }: {
  imports = [
    ./helix.nix
    ./vscode.nix
  ];

  options.my.user.dev.editors = {
    helix.enable = tools.opt.mkRiding config.my.user.dev.enable "Helix editor + config";
    vscode.enable = tools.opt.mkDisabled "VS Code (install only, no settings)";
  };
}
