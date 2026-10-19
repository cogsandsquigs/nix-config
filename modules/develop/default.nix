{ self, ... }: {
    flake.modules.homeManager.dev = {
        imports = [ self.modules.homeManager."develop/languages" ];
    };
}
