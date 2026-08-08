# ip-workbox -- x86_64-linux work machine running Ubuntu 24.
#
# NOT a NixOS/nix-darwin system: Nix is per-user and this is applied with *standalone* home-manager
# (`home-manager switch --flake ...#ipratt@ip-workbox`). `class = "home"` (./id.nix), so tools/default.nix
# builds it straight from the user unit, skipping the system-class features.
#
# The feature set, git identity and flake path live in the portable user unit (users/ipratt/). Username
# and platform come from ./id.nix. What is left here belongs to the MACHINE: Ubuntu's graphics stack.
_: {
    _class = "homeManager";

    # ghostty comes from apt here. Its GTK is 4.14, which predates `wp_cursor_shape_v1` and so keeps
    # drawing its own pointer. Every nix-built GTK4 client (4.22) instead defers to mutter 46, which
    # sizes it wrong. Verified against gnome-calculator, so this is the toolkit, not the terminal.
    # Installing it locally also drops the need for an OpenGL wrapper -- there is no store binary to
    # wrap, which is why no host pulls nixGL in.
    my.user.cli.terminal.localInstall.enable = true;

    # Ubuntu ships the FHS loader nvm's prebuilt node binaries need, which is what makes this feature
    # sound here and not on a NixOS host.
    my.user.dev.nvm.enable = true;

    # Store-built GUI apps get none of Ubuntu's data dirs, so ghostty could not load the Yaru cursor
    # theme and drew an oversized fallback pointer over its own window. This is the module that owns
    # that glue -- XCURSOR_PATH, XDG_DATA_DIRS, distro terminfo.
    targets.genericLinux.enable = true;
}
