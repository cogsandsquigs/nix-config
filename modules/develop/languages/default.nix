{ self, ... }: {
    flake.modules.homeManager."develop/languages" = {
        imports = [ self.modules.homeManager."develop/languages/rust" ];
    };
}
