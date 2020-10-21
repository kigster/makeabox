#!/usr/bin/env bash

#——————————————————————————————————————————————————————————————————————————————
# BASHMATIC
#——————————————————————————————————————————————————————————————————————————————
function puma.load-bashmatic() {
  local bashmatic_bootstrap_script="https://bit.ly/bashmatic-install)"
  local bashmatic_home="${HOME}/.bashmatic"

  [[ -d ${bashmatic_home} ]] || bash -c "$(curl -fsSL "${bashmatic_bootstrap_script}")" >/dev/null

  [[ -f ${bashmatic_home}/init.sh ]] || {
    echo "Can't find Bashmatic, please install it with:"
    echo "    $ curl -fsSL ${bashmatic_bootstrap_script} | bash"
    exit 1
  }

  # shellcheck disable=SC1090
  source "${bashmatic_home}/init.sh"
}

#——————————————————————————————————————————————————————————————————————————————
# PIDS
#——————————————————————————————————————————————————————————————————————————————
function pid.from.ps() {
  # shellcheck disable=SC2207
  local -a pids=( $(/bin/ps -ef | grep -E '[p]uma.*makeabox' | grep -v cluster) )
  [[ ${pids[1]} =~ [:digit] ]] && {
    local pid=${pids[1]}
    pid.valid "${pid}" && printf "%d" "${pid}" && return
  }
  return 1
}

function pid.from.file() {
  local pid
  local pid_file="${CURRENT_PATH:-${PWD}}/tmp/pids/puma.pid"

  test -f "${pid_file}" && {
    pid="$(cat "${pid_file}")"
    pid.valid "${pid}" && echo "${pid}" && return
  }
  return 1
}

function pid.valid() {
  [[ -z "$1" ]] && return 1
  /bin/ps -p "$1" | grep -v PID | grep -q "$1"
}

function pid.kill() {
  local signal="$1"
  local pid="$(pid.from.file || pid.from.ps)"

  if [[ -n "${pid}" ]]; then
    info "Puma Master process detected, PID=$pid\n"
    inf "Sending signal ${signal} to ${pid}..."
    kill -"${signal/-/}" "${pid}" 2>/dev/null 1>/dev/null

    sleep 0.5

    if pid.valid "${pid}"; then
      not-ok:
      return 1
    else
      ok:
    fi
  fi
}

#——————————————————————————————————————————————————————————————————————————————
# ENV
#——————————————————————————————————————————————————————————————————————————————

function puma.source-environment() {
  local -a init_files
  # shellcheck disable=SC2206
  init_files+=( $@ )
  init_files+=("${HOME}}/.bashrc")

  export APP="makeabox"
  export RAILS_ENV="production"
}

