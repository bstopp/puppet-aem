#!/bin/bash


idx=0
while [  $idx -lt 60 ]; do
  resp_code=`curl -s -o /dev/null -w "%{http_code}" http://localhost:4502`
  if [[ $? -eq 0 ]] && [[ $resp_code =~ (302|401|200) ]]; then
    exit 0
  fi
 sleep 10
 let idx=idx+1
done

