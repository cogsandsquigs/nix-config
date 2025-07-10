{ pkgs, ... }:
{
  # User-only packages
  home.packages = with pkgs; [
    docker
    docker-compose
    podman
    podman-compose
    minikube
    kubectl
    kompose # Docker compose -> kubernetes
  ];
}
