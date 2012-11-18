#!/bin/bash

function check_prior_crashes() {
    rlAssert0 "No prior crashes recorded" $(abrt-cli list | wc -l)
    if [ ! "_$(abrt-cli list | wc -l)" == "_0" ]; then
        rlDie "Won't proceed"
    fi
}

function get_crash_path() {
    rlLog "Get crash path"
    rlAssertGreater "Crash recorded" $(abrt-cli list | wc -l) 0
    crash_PATH="$(abrt-cli list -f | grep Directory | awk '{ print $2 }' | tail -n1)"
    if [ ! -d "$crash_PATH" ]; then
        rlDie "No crash dir generated, this shouldn't happen"
    fi
    rlLog "PATH = $crash_PATH"
}

function wait_for_process() {
    local procname=$1
    local timeout=3000
    if [ $# -gt 1 ]; then
        timeout=$2
    fi
    rlLog "Waiting for $procname to end"
    local c=0
    while pidof "$procname" &> /dev/null; do
        sleep 0.1
        let c=$c+1
        if [ $c -gt $timeout ]; then
            rlFail "Timeout"
            break
        fi
    done
    t=$( echo "scale=2; $c/10" | bc )
    rlLog "Process ended in $t seconds"
}

function wait_for_sosreport() {
    wait_for_process sosreport
}

function wait_for_hooks() {
    rlLog "Waiting for all hooks to end"
    local c=0
    while [ ! -f /tmp/abrt-done ]; do
        sleep 0.1
        let c=$c+1
        if [ $c -gt 3000 ]; then
            rlFail "Timeout"
            break
        fi
    done
    t=$( echo "scale=2; $c/10" | bc )
    rlLog "Hooks ended in $t seconds"
}

function generate_crash() {
    rlLog "Generate crash"
    will_segfault
}

function generate_second_crash() {
    rlLog "Generate second crash"
    will_abort
}

function prepare() {
    rm -f /var/spool/abrt/last-ccpp
    rm -f /tmp/abrt-done
}
