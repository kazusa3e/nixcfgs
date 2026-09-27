#!/usr/bin/env bash
set -euo pipefail

container_name=seafile-sync

if [[ $(id -un) != kazusa ]]; then
  printf 'Run this command as kazusa.\n' >&2
  exit 1
fi

if [[ ! -t 0 || ! -t 1 ]]; then
  printf 'An interactive terminal is required.\n' >&2
  exit 1
fi

if [[ $(podman inspect --format '{{.State.Running}}' "$container_name" 2>/dev/null) != true ]]; then
  printf 'The %s container is not running. Check systemctl --user status seafile-sync.\n' "$container_name" >&2
  exit 1
fi

prompt_required() {
  local prompt=$1
  REPLY=
  while [[ -z $REPLY ]]; do
    read -r -p "$prompt" REPLY || exit 1
  done
}

prompt_required 'Seafile URL (https://...): '
server=${REPLY%/}
case $server in
  http://* | https://*) ;;
  *) printf 'The URL must start with http:// or https://.\n' >&2; exit 1 ;;
esac

prompt_required 'Username: '
username=$REPLY

prompt_required 'Library ID: '
library_id=$REPLY

if podman exec "$container_name" test -f /state/.seafile.conf; then
  read -r -p 'Authentication: [r]euse saved token, [p]assword, or [t]oken? [r]: ' auth_mode
  auth_mode=${auth_mode:-r}
else
  read -r -p 'Authentication: [p]assword or [t]oken? [p]: ' auth_mode
  auth_mode=${auth_mode:-p}
fi

case $auth_mode in
  p | P)
    user_config=/dev/null
    ;;
  r | R)
    if ! podman exec "$container_name" test -f /state/.seafile.conf; then
      printf 'There is no saved API token.\n' >&2
      exit 1
    fi
    user_config=/state/.seafile.conf
    ;;
  t | T)
    read -r -s -p 'API token: ' token || exit 1
    printf '\n'
    if [[ -z $token ]]; then
      printf 'The API token cannot be empty.\n' >&2
      exit 1
    fi
    printf '[account]\nserver = %s\nuser = %s\ntoken = %s\n' \
      "$server" "$username" "$token" |
      podman exec -i "$container_name" /bin/sh -c \
        'umask 077; cat > /state/.seafile.conf; chmod 0600 /state/.seafile.conf'
    unset token
    user_config=/state/.seafile.conf
    ;;
  *)
    printf 'Choose r, p, or t.\n' >&2
    exit 1
    ;;
esac

args=(
  download
  -c /state/.ccnet
  -C "$user_config"
  -l "$library_id"
  -s "$server"
  -d /sync
  -u "$username"
)

if [[ $auth_mode == p || $auth_mode == P ]]; then
  read -r -p 'Two-factor code (leave empty if unused): ' tfa_code
  if [[ -n $tfa_code ]]; then
    args+=(--tfa "$tfa_code")
  fi
fi

podman exec -it "$container_name" seaf-cli "${args[@]}"

printf '\nSync status:\n'
podman exec "$container_name" seaf-cli status -c /state/.ccnet
