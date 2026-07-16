{ pkgs, ... }: {
    lang = [ "java" ];

    pkgs = with pkgs; [
        openjdk11
        swt
        gradle
        kotlin
    ];
}
