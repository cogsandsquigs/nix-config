{ pkgs, ... }: {
    mattpocock-skills = pkgs.fetchFromGitHub {
        owner = "mattpocock";
        repo = "skills";
        rev = "8b78b531ab965735c5dc74f6f7a219e1e37326df";
        hash = "sha256-jsXcMkhu15MxR0zXnLLJeni0q0Aew2UxUSojl6zmOvg=";
    };
}
