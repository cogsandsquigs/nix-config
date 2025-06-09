{pkgs, ...}: {
    # NOTE: We do this so that we can include everything we "usually" want.
    # The `darwin` module is `all` + any darwin-specific modules.
    imports = [
        ../all
    ];

    home.packages = with pkgs; [
        raycast
        net-news-wire
        skimpdf
        pinentry_mac
        mkalias
        openssl
    ];
}
