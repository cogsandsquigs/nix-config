{ self, ... }: {
    flake.modules.homeManager.apps.imports = [
        self.modules.homeManager."apps/ghostty"
        self.modules.homeManager."apps/git"
        self.modules.homeManager."apps/ssh"
        self.modules.homeManager."apps/browsers"
        self.modules.homeManager."apps/obsidian"
        self.modules.homeManager."apps/helix"
        self.modules.homeManager."apps/zellij"
        self.modules.homeManager."apps/yazi"
    ];
}
