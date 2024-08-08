#!/bin/zsh

##? uptime.as -- Get data from uptime.as
##?
##? usage: uptime.as <uptime>

curl --silent "https://get.uptime.is/api?sla=${1}" | jq .
