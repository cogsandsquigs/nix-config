{ inputs, ... }:
{
    flake.darwinConfigurations = inputs.self.lib.mkDarwin "aarch64-darwin" "Ians-GlorpBook-Pro";
}
