#!/bin/bash

working_dir=$(pwd)

function runCommand() {
    local counter=0
    local cmd=$1
    local reportFile=$2

    until [ $counter -gt 2 ]
    do
        eval "$cmd"
        if [ -f $reportFile ] && [ -s $reportFile ]
        then
            break 1
        else
            counter=$(( counter + 1 ))
        fi
    done
}

function run_axe() {
  axe_dirs=("$@")

  for axe_dir in "${axe_dirs[@]}"
  do
    commandString="axe \"file://${working_dir}/${axe_dir}/index.html\" --no-reporter --save axe-report.json --dir $axe_dir >/dev/null"
    runCommand "${commandString}" "$axe_dir/axe-report.json"
  done
}

function run_vnu() {
  vnu_dirs=("$@")

  for vnu_dir in "${vnu_dirs[@]}"
  do
    commandString="vnu --format json \"$vnu_dir/index.html\" &> $vnu_dir/vnu-report.json"
    runCommand "$commandString" "$vnu_dir/vnu-report.json"
  done
}

function run_pa11y() {
  pa11y_dirs=("$@")

  for pa11y_dir in "${pa11y_dirs[@]}"
  do
    commandString="pa11y -c ~/pa11y-config.json --reporter json --include-warnings \"$working_dir/$pa11y_dir/index.html\" | jq . &> $pa11y_dir/pa11y-report.json"
    runCommand "$commandString" "$pa11y_dir/pa11y-report.json"
  done
}

declare -a pids
read -a directories <<< $(find "test-suites/${1}/page-capture-service" -mindepth 2 -type d | tr '\n' ' ')

run_axe "${directories[@]}" &
pids[0]=$!
run_pa11y "${directories[@]}" &
pids[1]=$!
run_vnu "${directories[@]}" &
pids[2]=$!

for pid in ${pids[*]}; do
    wait $pid
done
