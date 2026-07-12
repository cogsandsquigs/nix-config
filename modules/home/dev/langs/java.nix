{ pkgs, ... }: {
  lang = [ "java" ];

  pkgs = with pkgs; [
    jdk
    gradle
    kotlin
  ];
}
