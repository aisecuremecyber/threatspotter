#!/bin/bash
#Any change made in this script needs to be made in upgrade-agent.sh script and
#in the golang code that uses that script
usage() {

  cat <<EOF

	usage: $0 <options>

	OPTIONS:
        -h Show this message
        -r IP Address of Deepfence management console vm (Mandatory)
        -k Deepfence key for auth (Optional, depending on the setup of Deepfence Console)
        -n Hostname to use in deepfence agent (Optional)
        -t User defined tags, comma separated string (Optional)

EOF
}

MGMT_CONSOLE_IP_ADDR=""
USER_DEFINED_TAGS=""
DEEPFENCE_KEY=""
DF_HOSTNAME=""

check_options() {
  if [ "$#" -lt 1 ]; then
    usage
    exit 0
  fi
  while getopts "k:n:r:t:h" opt; do
    case $opt in
    h)
      usage
      exit 0
      ;;
    r)
      MGMT_CONSOLE_IP_ADDR=$OPTARG
      ;;
    k)
      DEEPFENCE_KEY=$OPTARG
      ;;
    n)
      DF_HOSTNAME=$OPTARG
      ;;
    t)
      USER_DEFINED_TAGS="$OPTARG"
      ;;
    *)
      usage
      exit 0
      ;;
    esac
  done
  if [ "$MGMT_CONSOLE_IP_ADDR" == "" ]; then
    usage
    exit 0
  fi
  if [ "$DF_HOSTNAME" == "" ]; then
    DF_HOSTNAME=$(hostname)
  fi
}

kill_agent() {
  agent_running=$(docker ps --format '{{.Names}}' | grep "deepfence-agent")
  if [ "$agent_running" != "" ]; then
    docker rm -f deepfence-agent
  fi
}

start_agent() {
  docker run -dit --cpus=".2" --name=deepfence-agent --restart on-failure --pid=host --net=host --privileged=true -v /sys/kernel/debug:/sys/kernel/debug:rw -v /var/log/fenced -v /var/run/docker.sock:/var/run/docker.sock -v /:/fenced/mnt/host/:ro -e USER_DEFINED_TAGS="$USER_DEFINED_TAGS" -e DF_BACKEND_IP="$MGMT_CONSOLE_IP_ADDR" -e SCOPE_HOSTNAME="$DF_HOSTNAME" -e DEEPFENCE_KEY="$DEEPFENCE_KEY" deepfenceio/deepfence_agent_ce:latest
}

main() {
  check_options "$@"
  kill_agent
  start_agent
}

main "$@"
