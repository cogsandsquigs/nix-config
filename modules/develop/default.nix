{ self, ... }: {
    flake.modules.homeManager.develop = {
        imports = [ self.modules.homeManager."develop/languages" ];
    };
}
