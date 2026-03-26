{ ... }:
{

    # Each attribute in `meta.languages` is as follows:
    # ```
    # {
    #     <name> = {
    #         pkgs = [ ... ]; # List of packages needed for that programming language
    #
    #         language-servers = {
    #             <name> = {
    #                 cmd = "...";
    #                 args = [ ... ];
    #             };
    #
    #             ...
    #         };
    #
    #         formatting = {
    #             cmd = "...";
    #             args = [ ... ];
    #             options = { ... };
    #         };
    #     };
    #
    #     ...
    # }
    # ```
    flake.modules.meta.languages =
        { pkgs, ... }:
        {

        };
}
