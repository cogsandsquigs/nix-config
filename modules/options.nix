# Configuration options shared across all the config.
{ lib, ... }: {
    options.me = {
        username = lib.mkOption {
            type = lib.types.str;
            description = "The primary user's username";
        };
    };

    config.me = {
        username = "cogs";
    };
}
