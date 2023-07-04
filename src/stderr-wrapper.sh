#!/bin/bash

while read err; do
	now=$(date +%Y-%m-%dT%H:%M:%S.00Z)
	# escape for json: \ -> \\
	err="${err//\\/\\\\}"
	# escape for json: " -> \"
	err="${err//\"/\\\"}"
	echo "{\"timestamp\":\"${now}\",\"level\":\"ERROR\",\"message\":\"${err}\"}"
done
