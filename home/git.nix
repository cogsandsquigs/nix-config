{pkgs, ...}: {
  programs.git = {
    enable = true;
    # Basic user settings
    userName = "Ian Pratt";
    userEmail = "ianjdpratt@gmail.com";

    signing = {
      key = "E0DB58169CA551AA!";
      signByDefault = true;
      # signer = "${pkgs.gnupg}/bin/gpg"; # NOTE: See `extraConfig.gpg.program`
    };

    # Diff highlighting
    delta = {
      enable = true;

      options = {
        diff-highlight = true;
      };
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

      # For some reason `signing.signer` doesn't set the GPG program, so I gotta do this
      gpg.program = "${pkgs.gnupg}/bin/gpg";
    };
  };
}
