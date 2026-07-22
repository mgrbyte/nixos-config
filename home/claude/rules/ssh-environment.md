# SSH Environment (macOS)

How ssh works on this home-manager/nix-managed MacOS, and what Claude must and must not suggest when it breaks.
(Captured 2026-07-22 after the UseKeychain suggestion recurred across many sessions.)

## The setup

- `ssh` is the **nix-profile OpenSSH** (`~/.nix-profile/bin/ssh`), not Apple's `/usr/bin/ssh`.
- Private keys are **passphrase-protected**, age-encrypted in nix-secrets, and decrypted to
  `~/.secrets/` by the home-manager-secrets launchd job; `~/.ssh/id_*` are symlinks into it.
- The agent is Apple's launchd `ssh-agent` (`SSH_AUTH_SOCK` under `/var/run/com.apple.launchd.*`).
- Keys reach the agent **lazily**: `AddKeysToAgent yes` adds a key only after a successful
  interactive use (TTY passphrase prompt). Nothing re-primes the agent automatically.

## The recurring failure

Any agent restart (reboot, or the agent dying mid-session) empties the agent. The next
**non-TTY** ssh consumer (magit push, emacs) then fails: nix OpenSSH ships no askpass and
`SSH_ASKPASS` is unset, so ssh falls back to an empty passphrase →
`Permission denied (publickey)`.

Diagnosis pattern: `ssh-add -l` says "no identities"; `ssh-keygen -y -f <key>` from a non-TTY
shows `ssh_askpass: exec(...) ... incorrect passphrase supplied`; secrets in `~/.secrets/` are
intact (the decrypt side is rarely the fault — check its log at
`~/.cache/home-manager-secrets.log` only after ruling out the agent).

## Rules for Claude

- **NEVER suggest `UseKeychain`, `--apple-load-keychain`, or routing git through
  `/usr/bin/ssh`.** Proposed many times; does not work in this environment (unsupported by the
  nix-profile ssh; see nix-config history: `d9e5c17`, `0300531`). Do not relitigate.
- **Interim unblock** (any shell — passphrases come from the macOS Keychain, no TTY needed):
  `/usr/bin/ssh-add --apple-load-keychain`
- **The working mechanism**: passphrases are stored in the macOS Keychain (age.nix
  `loadSshKeysToAgent` activation); `/usr/bin/ssh-add --apple-load-keychain` reloads the agent
  from it non-interactively. The Apple ssh-add *flags* work fine — only the `UseKeychain`
  *config option* is fatal to nix ssh.
- **Durable fix (2026-07-22)**: `launchd.agents.ssh-load-keychain` in ssh.nix — RunAtLoad +
  WatchPaths on `~/.ssh/agent` (a fresh socket appears there when the agent restarts), running
  the Keychain reload with output logged to `~/.cache/ssh-load-keychain.log`. The zshrc loader
  remains as belt-and-braces.
- `glab`/API tooling authenticates over HTTPS with tokens — GitLab issue/MR operations are NOT
  blocked by an empty ssh agent; only pushes/pulls over ssh are.
