{ ... }:
{
    flake.modules.homeManager.browser =
        { config, pkgs, ... }:
        {
            # home.packages = with pkgs; [ librewolf ];

            programs.librewolf = {
                enable = true;
                # package = pkgs.librewolf;
                languagePacks = [ "en-US" ];

                policies = {
                    # Updates & Background Services
                    AppAutoUpdate = false;
                    BackgroundAppUpdate = false;

                    # Feature Disabling
                    # DisableBuiltinPDFViewer = true;
                    # DisableFirefoxStudies = true;
                    # DisableFirefoxAccounts = true;
                    # DisableFirefoxScreenshots = true;
                    # DisableForgetButton = true;
                    # DisableMasterPasswordCreation = true;
                    # DisableProfileImport = true;
                    # DisableProfileRefresh = true;
                    # DisableSetDesktopBackground = true;
                    DisablePocket = true;
                    DisableTelemetry = true;
                    # DisableFormHistory = true;
                    # DisablePasswordReveal = true;

                    # UI and Behavior
                    # DisplayMenuBar = "never";
                    DontCheckDefaultBrowser = true;
                    HardwareAcceleration = true;
                    OfferToSaveLogins = false;
                };

                profiles.default = {
                    settings = {
                        "browser.startup.homepage" = "about:blank";

                        "browser.ai.control.default" = "blocked";
                        "browser.ai.control.linkPreviewKeyPoints" = "blocked";
                        "browser.ai.control.pdfjsAltText" = "blocked";
                        "browser.ai.control.sidebarChatbot" = "blocked";
                        "browser.ai.control.smartTabGroups" = "blocked";
                        "browser.ai.control.translations" = "available";

                        "privacy.resistFingerprinting" = true;
                    };

                    search = {
                        force = true;

                        default = "SearXNG";
                        privateDefault = "SearXNG";

                        engines = {
                            "SearXNG" = {
                                urls = [
                                    {
                                        template = "https://searxng.cogsandsquigs.dev/search";
                                        params = [
                                            {
                                                name = "q";
                                                value = "{searchTerms}";
                                            }
                                        ];
                                        definedAliases = [ "@sxng" ];
                                    }
                                ];
                            };
                        };
                    };
                };
            };
        };
}
