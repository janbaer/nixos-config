{ config, ... }:
{
  # This let Agenix knows, which key for decrypting of home-secrets has to be used
  # and where to find it
  age.identityPaths = [ "/run/agenix/agenix-home-key" ];
}

