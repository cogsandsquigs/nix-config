{ self, ... }: {
    flake.modules.homeManager.apps.imports = map (n: self.modules.homeManager.${n}) [
        "apps/ghostty"
        "apps/git"
        "apps/ssh"
        "apps/browsers"
        "apps/messaging"
        "apps/obsidian"
        "apps/helix"
        "apps/zellij"
        "apps/yazi"
        "apps/pdfs"
        "apps/zoom"
        "apps/pomodoro"
        "apps/just"
    ];

    flake.modules.darwin.apps.imports = map (n: self.modules.darwin.${n}) [
        "apps/browsers"
        "apps/messaging"
        "apps/pdfs"
        "apps/pomodoro"
    ];
}
