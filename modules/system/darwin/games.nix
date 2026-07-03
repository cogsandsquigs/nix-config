# NOTE: currently nix-darwin can't manage steam, so we just use homebrew to install it for now.
{ ... }:
{
    homebrew = {
        casks = [
            "steam"
            "olympus" # Celeste mod loader # NOTE: for some reason not supported on nix aarch-64
            "porting-kit" # Windows -> Mac games
        ];
    };
}
