# VS Code — install only, no settings (deliberate: the work box wants the app, but its config is
# managed elsewhere / left to the GUI). Opt-in via `my.user.dev.editors.vscode.enable` (declared in
# ./default.nix). Off everywhere by default.
{
    pkgs,
    lib,
    config,
    ...
}:
{
    config = lib.mkIf config.my.user.dev.editors.vscode.enable {
        home.packages = with pkgs; [ vscode ];

        programs.vscode = {
            enable = true;
        };
    };
}

#Settings.json
/*
  {
    "workbench.startupEditor": "none",
    "editor.fontFamily": "'FiraCode Nerd Font Mono', 'Fira Code', 'Droid Sans Mono', monospace",
    "explorer.confirmDragAndDrop": false,
    "claudeCode.preferredLocation": "sidebar",
    "editor.rulers": [100],
    "workbench.colorTheme": "Catppuccin Mocha",
    "workbench.iconTheme": "catppuccin-mocha",
    "[markdown]": {
      "editor.defaultFormatter": "esbenp.prettier-vscode",
    },
    "editor.formatOnSave": true,
    "notebook.formatOnSave.enabled": true,
    "[json]": {
      "editor.defaultFormatter": "esbenp.prettier-vscode",
    },
    "editor.wordWrapColumn": 100,
    "chat.agent.enabled": false,
    "debug.console.wordWrap": false,
    "git.enableSmartCommit": true,
    "[jsonc]": {
      "editor.defaultFormatter": "esbenp.prettier-vscode",
    },
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "chat.disableAIFeatures": true,
    "claudeCode.hideOnboarding": true,
    "eslint.format.enable": true,
    "eslint.useESLintClass": true,
    "git.autofetch": true,
  }
*/
