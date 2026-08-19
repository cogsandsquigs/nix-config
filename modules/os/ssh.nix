let
    conf = _: {
        # SSH terminfo enable
        environment.enableAllTerminfo = true;
    };

in
{
    nixos = conf;
    darwin = conf;
}
