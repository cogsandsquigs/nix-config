{ pkgs, ... }: {
    lang = [ "java" ];

    pkgs = with pkgs; [
        openjdk11
        swt
        jdk
        gradle
        kotlin
    ];
}
