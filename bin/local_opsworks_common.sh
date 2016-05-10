#!/bin/bash

action="$1"

base_box="harvard-dce/local-opsworks-ubuntu1404"
if ! (vagrant box list | grep -q "$base_box"); then
  vagrant box add "$base_box"
  sleep 5
fi

start_timing(){
  start_time=$(date +%s)
}

display_elapsed_time(){
  end_time=$(date +%s)

  elapsed=$[$end_time - $start_time]
  echo
  echo "$action took $elapsed seconds"
  echo
}
