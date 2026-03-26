{ lib, ... }:
{
    flake.modules.homeManager.browser =
        { config, pkgs, ... }:
        {
            # home.packages = with pkgs; [ librewolf ];

            programs.librewolf = {
                enable = true;
                # package = pkgs.librewolf;
                languagePacks = [ "en-US" ];

                profiles.default = {
                    settings = {
                        # "browser.startup.homepage" = "about:blank";
                        "browser.startup.homepage" = "https://searxng.cogsandsquigs.dev";

                        "browser.ai.control.default" = "blocked";
                        "browser.ai.control.linkPreviewKeyPoints" = "blocked";
                        "browser.ai.control.pdfjsAltText" = "blocked";
                        "browser.ai.control.sidebarChatbot" = "blocked";
                        "browser.ai.control.smartTabGroups" = "blocked";
                        "browser.ai.control.translations" = "available";

                        # "privacy.resistFingerprinting" = true;
                        "privacy.resistFingerprinting" = false;
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

                    # Extensions
                    ExtensionSettings =
                        let
                            moz =
                                short:
                                "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
                        in
                        {
                            "*".installation_mode = "blocked";

                            "uBlock0@raymondhill.net" = {
                                install_url = moz "ublock-origin";
                                installation_mode = "force_installed";
                                updates_disabled = true;
                            };

                            "{f3b4b962-34b4-4935-9eee-45b0bce58279}" = {
                                install_url = moz "animated-purple-moon-lake";
                                installation_mode = "force_installed";
                                updates_disabled = true;
                            };

                            "{73a6fe31-595d-460b-a920-fcc0f8843232}" = {
                                install_url = moz "noscript";
                                installation_mode = "force_installed";
                                updates_disabled = true;
                            };
                        };

                    # Extension configuration
                    "3rdparty".Extensions = {
                        "uBlock0@raymondhill.net".adminSettings = {
                            userSettings = rec {
                                uiTheme = "dark";
                                uiAccentCustom = true;
                                uiAccentCustom0 = "#8300ff";
                                cloudStorageEnabled = lib.mkForce false;

                                importedLists = [
                                    "https:#filters.adtidy.org/extension/ublock/filters/3.txt"
                                    "https:#github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
                                ];

                                externalLists = lib.concatStringsSep "\n" importedLists;
                            };

                            selectedFilterLists = [
                                "CZE-0"
                                "adguard-generic"
                                "adguard-annoyance"
                                "adguard-social"
                                "adguard-spyware-url"
                                "easylist"
                                "easyprivacy"
                                "https:#github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
                                "plowe-0"
                                "ublock-abuse"
                                "ublock-badware"
                                "ublock-filters"
                                "ublock-privacy"
                                "ublock-quick-fixes"
                                "ublock-unbreak"
                                "urlhaus-1"
                            ];
                        };
                    };
                };
            };
        };
}
