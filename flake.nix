{
  inputs = {
    everest = {
      url = github:project-everest/everest-nix?dir=projects;
      # `/` means `self` (see NixOS/nix#4931)
      inputs.hacl-src.follows     = "/";
    };
  };

  outputs = { everest, ... }: everest;
}
