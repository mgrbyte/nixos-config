#!/bin/bash
# PreToolUse(Bash) allow-hook for unattended cruft-sweep housekeeping.
# Auto-allows ONLY these exact command shapes, scoped to ~/gitlab:
#   [cd /Users/mtr21pqh/gitlab/<path> && ] rm -rf .venv
#   [cd /Users/mtr21pqh/gitlab/<path> && ] rm [-f] <tokens all ending in .rej>
# Anything else (other args, chained commands, shell metacharacters) falls
# through to the normal permission flow. Emitting nothing = no opinion.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$cmd" ] || exit 0
case "$cmd" in
  *';'* | *'|'* | *'`'* | *'$'* | *'<'* | *'>'* | *'('* | $'*\n*') exit 0 ;;
esac
gitlab_cd='^cd /Users/mtr21pqh/gitlab/[A-Za-z0-9._{}/-]+ && '
allow() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}
in_gitlab=no
case "$cwd" in /Users/mtr21pqh/gitlab/*) in_gitlab=yes ;; esac
venv_re='rm -rf (\./)?\.venv/?$'
rej_re='rm (-f )?([A-Za-z0-9._{}/*-]+\.rej )*[A-Za-z0-9._{}/*-]+\.rej$'
if printf '%s' "$cmd" | grep -qE "${gitlab_cd}${venv_re}"; then
  allow "cruft sweep: recreate .venv under ~/gitlab"
fi
if printf '%s' "$cmd" | grep -qE "${gitlab_cd}${rej_re}"; then
  allow "cruft sweep: remove cruft .rej files under ~/gitlab"
fi
if [ "$in_gitlab" = yes ]; then
  if printf '%s' "$cmd" | grep -qE "^${venv_re}"; then
    allow "cruft sweep: recreate .venv in ~/gitlab cwd"
  fi
  if printf '%s' "$cmd" | grep -qE "^${rej_re}"; then
    allow "cruft sweep: remove cruft .rej files in ~/gitlab cwd"
  fi
fi
exit 0
