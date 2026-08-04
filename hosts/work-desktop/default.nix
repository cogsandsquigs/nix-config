# work-desktop -- x86_64-linux work machine running Ubuntu 24.
#
# This is NOT a NixOS/nix-darwin system: Nix is installed per-user, and this config is applied with
# *standalone* home-manager (`home-manager switch --flake ...#ipratt@work-desktop`). Its `class` is
# "home" (see ./id.nix), so it does not go through the system-class features --
# tools/default.nix builds it directly from the user unit.
#
# Identity, the home feature set, git identity, and the flake checkout path all live in the portable
# user unit (users/ipratt/), and home.username + platform come from ./id.nix. What is left here is
# what belongs to the MACHINE rather than the user: Ubuntu's own graphics stack.
_: {
    _class = "homeManager";

    # ghostty comes from apt here. Its GTK is 4.14, which predates `wp_cursor_shape_v1` and so keeps
    # drawing its own pointer; every nix-built GTK4 client (4.22) instead defers to mutter 46, which
    # sizes it wrong. Verified against gnome-calculator, so this is the toolkit, not the terminal.
    # Installing it locally also drops the need for nixGL -- there is no store binary to wrap.
    my.user.cli.terminal.localInstall.enable = true;

    # Store-built GUI apps get none of Ubuntu's data dirs, so ghostty could not load the Yaru cursor
    # theme and drew an oversized fallback pointer over its own window. This is the module that owns
    # that glue -- XCURSOR_PATH, XDG_DATA_DIRS, distro terminfo -- and whose nixGL half is already in
    # use above.
    targets.genericLinux.enable = true;
}
