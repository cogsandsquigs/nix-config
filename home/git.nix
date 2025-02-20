{pkgs, ...}: {
  programs.git = {
    enable = true;
    # Basic user settings
    userName = "Ian Pratt";
    userEmail = "ianjdpratt@gmail.com";

    signing = {
      key = "E0DB58169CA551AA!";
      gpgPath = "${pkgs.gnupg}/bin/gpg2";
      signByDefault = true;
    };

    # Diff highlighting
    delta = {
      enable = true;
    };

    # Extra configuration for sections not provided by top-level options:
    extraConfig = {
      url = {
        "ssh://git@github.com/" = {
          insteadOf = "https://github.com/";
        };
        "ssh://git@gitlab.doc.ic.ac.uk/" = {
          insteadOf = "https://gitlab.doc.ic.ac.uk/";
        };
      };

      core.autocrlf = "input";
      init.defaultBranch = "main"; # Default new branch is `main`
      pull.rebase = false; # Pull behavior: setting rebase to false

      # Credential helper
      # TODO: Dynamic based on host OS
      credential.credentialStore = "osxkeychain";
    };
  };
}
