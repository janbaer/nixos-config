function rsync_remote() {
  local server_address=$1
  local target_dir="${user}@${server_address}:/backup/${2}/"
  local user=$3
  local source_dir="$4"
  local exclude_from_file=$5

  echo "*******************************"
  echo "server_address: $server_address"
  echo "target_dir: $target_dir"
  echo "user: $user"
  echo "source_dir: $source_dir"
  echo "exclude_from_file: $exclude_from_file"
  echo "*******************************"

  echo "backup directory $source_dir to $target_dir"
  echo "------------------------------------------"

  rsync -avu --progress --delete                                  \
        --dry-run                                                 \
        --exclude-from="$exclude_from_file"                       \
        -e "ssh -i /home/$(whoami)/.ssh/id_ed25519-jabasoft-ug"   \
        "${source_dir}" "${target_dir}"
}

function rsync_local() {
  local target_dir="/run/media/jan/BACKUP-HD/${1}/"
  local source_dir="$2"
  local exclude_from_file=$3

  echo "*******************************"
  echo "target_dir: $target_dir"
  echo "source_dir: $source_dir"
  echo "exclude_from_file: $exclude_from_file"
  echo "*******************************"

  mkdir -p $target_dir

  echo "backup directory $source_dir to $target_dir"
  echo "------------------------------------------"

  rsync -avu --progress --delete            \
        --exclude-from="$exclude_from_file" \
        "${source_dir}" "${target_dir}"
}

function backup {
  local server_address=$1
  local hostname=$2
  local user=$3
  local source_dir=$4
  local exclude_from_file=$5

  echo "Create backup on target-device ${server_address} for computer $hostname for user $user at $(date +%d-%m-%yT%H:%M:%S)"

  local hostname_upper=$(echo $hostname | tr '[a-zA-Z]' '[A-Za-z]')
  local target_dir="$hostname_upper/$user"

  if [ "${server_address}" == "USB" ]; then
    rsync_local "$target_dir" "$source_dir" "$exclude_from_file"
  else
    rsync_remote "$server_address" "$target_dir" "$user" "$source_dir" "$exclude_from_file"
  fi
}

backup "$@"
