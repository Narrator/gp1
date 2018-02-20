#!/bin/bash

username="test"
password="kau78#$%"
cat << EOF | passwd $username 
$password
$password
EOF
