{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    poetry2nix.url = "github:nix-community/poetry2nix";
  };

  outputs = { self, nixpkgs, utils, poetry2nix }:
    let out = system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.cudaSupport = true;
          config.allowUnfree = true;
        };
        inherit (pkgs.cudaPackages) cudatoolkit;
        cudnn = pkgs.cudaPackages.cudnn;
        inherit (pkgs.linuxPackages) nvidia_x11;
        python = pkgs.python311;
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryEnv;
        pythonEnv = mkPoetryEnv {
          inherit python;
          projectDir = ./.;
          preferWheels = true;
        };
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = [pythonEnv nvidia_x11 cudatoolkit cudnn];
          shellHook = ''
            export CUDA_PATH=${cudatoolkit.lib}
            export LD_LIBRARY_PATH=${cudatoolkit.lib}/lib:${nvidia_x11}/lib:${cudnn.lib}/lib
            export EXTRA_LDFLAGS="-l/lib -l${nvidia_x11}/lib"
            export EXTRA_CCFLAGS="-i/usr/include"
          '';
        };
      }; in with utils.lib; eachSystem defaultSystems out;
}


