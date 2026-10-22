{ self, ... }: {
    flake.modules.homeManager."develop/languages" = {
        imports = [
            self.modules.homeManager."develop/languages/c-cpp"
            self.modules.homeManager."develop/languages/julia"
            self.modules.homeManager."develop/languages/nix"
            self.modules.homeManager."develop/languages/pest"
            self.modules.homeManager."develop/languages/python"
            self.modules.homeManager."develop/languages/rust"
            self.modules.homeManager."develop/languages/toml"
        ];
    };
}
