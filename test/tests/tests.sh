#!/bin/bash

printf >&2 "waiting for nginx to start .."
until nc 2>/dev/null -z client-redirect-proxy 8443; do
    sleep 0.1
done
printf >&2 "nginx is up\nrunning tests "

# This call logs an error to error_log because we're requesting a file that does not exist 
curl --cacert /tmp/issuing_ca -s https://client-redirect-proxy:9443/non-existing-file

#
# The line to the error_log should show up in the metrics. 
#
request_url="https://client-redirect-proxy:9443/metrics"
num=$((num + 1))
diff \
  <(curl 2>/dev/null --cacert /tmp/issuing_ca -s "$request_url") \
  <(cat /root/metrics-error_log.txt)
if [ $? -ne 0 ]; then
  echo >&2 "\nTEST $num FAILED: expected the metrics to show an error was logged to error_log, but this wasnt the case"
  exit 1
fi
printf .


# Check that all the uuids ending in 0 are redirected to AIS and that all uuids ending in 1 are redirected to PIS
# Test this for urls both with and without a trailing slash (https://host/?state=~ vs https://host?state=~)
num=0
while read method request_url expected_response; do
  num=$((num + 1))
  diff \
    <(curl -X $method --cacert /tmp/issuing_ca -s "$request_url") \
    <(echo -n "$expected_response")
  if [ $? -ne 0 ]; then
    echo >&2 "\nTEST $num FAILED: expected request_url=\"${request_url}\" to yield \"${expected_response}\" but it did not.  See diff output above."
    exit 1
  fi
  printf .
done < /root/proxy-test-cases.txt


# Test that a html page is served if no state parameter is present
request_url="https://client-redirect-proxy:8443?code=b"
num=$((num + 1))
diff \
  <(curl --cacert /tmp/issuing_ca -s "$request_url") \
  <(cat /root/client-redirect.html)
if [ $? -ne 0 ]; then
  echo >&2 "\nTEST $num FAILED: expected request_url=\"${request_url}\" to yield client-redirect.html, but it did not.  See diff output above."
  exit 1
fi
printf .

# Test that no html page is served if no state parameter is present in a POST request
request_url="https://client-redirect-proxy:8443?code=b"
num=$((num + 1))
diff \
  <(curl -X POST --cacert /tmp/issuing_ca -I "$request_url" | tr -d '\r' | grep 'HTTP\|Location') \
  <(cat <<EOF
HTTP/1.1 301 Moved Permanently
Location: https://www.yolt.com/error-pages/not-found
EOF
)
if [ $? -ne 0 ]; then
  echo >&2 "\nTEST $num FAILED: expected post without state to redirect but it did not."
  exit 1
fi
printf .

# Test that any other URL except the root path results in 410 Gone
request_url="https://client-redirect-proxy:8443/should-return-410-gone"
num=$((num + 1))
diff \
  <(curl --cacert /tmp/issuing_ca -I "$request_url" | tr -d '\r' | grep HTTP) \
  <(echo 'HTTP/1.1 410 Gone')
if [ $? -ne 0 ]; then
  echo >&2 "\nTEST $num FAILED: expected request_url=\"${request_url}\" to yield 410 Gone, but it did not.  See diff output above."
  exit 1
fi
printf .


# Sleep for a while, see prometheus-exporter.c for the reason (metrics are updated periodically)
sleep 3
curl 2>/dev/null >/dev/null --cacert /tmp/issuing_ca -s "https://client-redirect-proxy:8443/doesnt-matter"

#
# Check overall metrics
#
request_url="https://client-redirect-proxy:9443/metrics"
num=$((num + 1))
diff \
  <(curl 2>/dev/null --cacert /tmp/issuing_ca -s "$request_url") \
  <(cat /root/metrics-all.txt)
if [ $? -ne 0 ]; then
  echo >&2 "\nTEST $num FAILED: expected request_url=\"${request_url}\" to yield prometheus metrics, but it did not.  See diff output above."
  exit 1
fi
printf .



echo >&2 -e "\nALL $num TESTS OK"
