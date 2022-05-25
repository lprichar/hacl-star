{
  inputs = {
    fstar-src.url     = github:fstarlang/fstar/master
    fstar-src.flake   = false;
    karamel-src.url   = github:fstarlang/karamel/master;
    karamel-src.flake = false;

    everest = {
      url = github:project-everest/everest-nix?dir=projects;
      inputs.fstar-src.follows    = "fstar-src";
      inputs.karamel-src.follows  = "karamel-src";
      # `/` means `self` (see NixOS/nix#4931)
      inputs.hacl-src.follows     = "/";
    };
  };

  outputs = { everest, ... }: everest;
}
