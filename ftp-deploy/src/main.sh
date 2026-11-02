#!/bin/sh
# FTP Deploy Action entrypoint.
set -eu

ftp_server="${INPUT_FTP_SERVER:-}"
ftp_username="${INPUT_FTP_USERNAME:-}"
ftp_password="${INPUT_FTP_PASSWORD:-}"
ftp_port="${INPUT_FTP_PORT:-}"
local_dir="${INPUT_LOCAL_DIR:-.}"
remote_dir="${INPUT_REMOTE_DIR:-/}"
ssl_enabled="${INPUT_SSL_ENABLED:-true}"
exclude="${INPUT_EXCLUDE:-}"
dry_run="${INPUT_DRY_RUN:-false}"
parallel="${INPUT_PARALLEL:-4}"
timeout="${INPUT_TIMEOUT:-120}"
max_retries="${INPUT_MAX_RETRIES:-5}"
idle_timeout="${INPUT_IDLE_TIMEOUT:-300}"

missing=""
for name in ftp_server ftp_username ftp_password ftp_port; do
  eval "value=\$$name"
  if [ -z "$value" ]; then
    missing="$missing $name"
  fi
done
if [ -n "$missing" ]; then
  echo "ftp-deploy: missing required input(s):$missing" >&2
  exit 1
fi

case "$ftp_port" in
  ''|*[!0-9]*) echo "ftp-deploy: ftp_port must be a number, got '$ftp_port'" >&2; exit 1 ;;
esac

if [ ! -d "$local_dir" ]; then
  echo "ftp-deploy: local_dir '$local_dir' does not exist" >&2
  exit 1
fi

if [ "$ssl_enabled" = "true" ]; then
  ssl_allow="set ftp:ssl-allow true"
else
  ssl_allow="set ftp:ssl-allow false"
fi
if [ "$ftp_port" = "990" ]; then
  ssl_force="set ftp:ssl-force true"
else
  ssl_force="set ftp:ssl-force false"
fi

mirror_opts="-R --verbose --parallel=$parallel"
if [ "$dry_run" = "true" ]; then
  mirror_opts="$mirror_opts --dry-run"
  echo "ftp-deploy: dry run enabled; no files will be written"
fi
if [ -n "$exclude" ]; then
  old_ifs="$IFS"
  IFS=','
  for pattern in $exclude; do
    pattern="$(printf '%s' "$pattern" | sed -e 's/^ *//' -e 's/ *$//')"
    if [ -n "$pattern" ]; then
      mirror_opts="$mirror_opts --exclude-glob $pattern"
    fi
  done
  IFS="$old_ifs"
fi

start="$(date +%s)"
export LFTP_PASSWORD="$ftp_password"
lftp -u "$ftp_username" --env-password -p "$ftp_port" "$ftp_server" <<EOF
set cmd:fail-exit true
set net:max-retries $max_retries
set net:timeout $timeout
set net:reconnect-interval-base 5
$ssl_allow
$ssl_force
set ssl:verify-certificate false
set xfer:clobber true
mirror $mirror_opts "$local_dir" "$remote_dir"
quit
EOF
end="$(date +%s)"

transfer_time=$((end - start))
files_uploaded="$(find "$local_dir" -type f | wc -l | tr -d ' ')"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  printf 'files_uploaded=%s\n' "$files_uploaded" >> "$GITHUB_OUTPUT"
  printf 'transfer_time=%s\n' "$transfer_time" >> "$GITHUB_OUTPUT"
fi
echo "ftp-deploy: uploaded $files_uploaded files in ${transfer_time}s to $ftp_server:$remote_dir"
