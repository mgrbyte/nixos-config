{ pkgs, config, emacs-config, ... }:

# let
#  githubPublicKey = "ssh-ed25519 AAAA...";
# in
{

  # ".ssh/id_github.pub" = {
  #   text = githubPublicKey;
  # };

  # Emacs configuration from github:mgrbyte/emacs.d
  ".emacs.d/init.el".source = "${emacs-config}/init.el";
  ".emacs.d/lisp" = {
    source = "${emacs-config}/lisp";
    recursive = true;
  };
}
