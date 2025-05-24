
# Usage

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    initencRepo = {
      url = "github:initialencounter/nurpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # ...
};
  outputs = inputs @{ nixpkgs, ... }:
  {
    nixosConfigurations.ie = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        # 在 modules 的开头添加下面这几行
        ({
          nixpkgs.overlays = [
            (final: prev: {
              initencRepo = inputs.initencRepo.packages."${prev.system}";
            })
          ];
        })
        # 在 modules 的开头添加上面这几行

        ./configuration.nix
      ];
    };
  };
}
```

这样操作后，你就能用类似于 pkgs.initencRepo.easytier 的方式使用这个仓库了。

```nix
# configuration.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
      initencRepo.easytier
  ];
}
```