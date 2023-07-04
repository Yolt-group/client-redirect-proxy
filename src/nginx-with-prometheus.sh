#!/bin/bash

# nginx produces the access_log to stdout and the error_log to stderr
# we route the access_log to fd3 and reroute stderr to stdout to process the error_log using stderr-wrapper.sh
#
# outside the brackets we merge the access_log back into stdout by rerouting fd3 to stdout
# in summary:
# - the error_log are plain text lines, the script stderr-wrapper.sh transforms these lines to json
# - the access_log is produced by nginx as json
# the above 2 streams are merged and piped to the prometheus-exporter program that tracks metrics based 
# on the logstream 
#  
{ nginx -g 'daemon off;' 2>&1 1>&3 | /home/yolt/stderr-wrapper.sh; } 3>&1 | /home/yolt/prometheus-exporter
