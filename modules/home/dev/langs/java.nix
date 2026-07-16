{ pkgs, ... }: {
    lang = [ "java" ];

    pkgs = with pkgs; [
        swt
        jdk
        gradle
        kotlin
    ];
}
