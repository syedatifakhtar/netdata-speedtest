#!/bin/bash

# Netdata charts.d collector for fast.com internet speed test.
# Requires installed speedtest.com cli: `sudo apt-get install speedtest`
speedtest_update_every=600
speedtest_priority=100

speedtest_check() {
  require_cmd speedtest || return 1
  return 0
}


speedtest_create() {
	# create a chart with 2 dimensions
	cat <<EOF
CHART system.connectionspeed '' "System Connection Speed" "Mbps" "connection speed" system.connectionspeed line $((speedtest_priority + 1)) $speedtest_update_every
DIMENSION down 'Down' absolute 1 1000
DIMENSION up 'Up' absolute 1 1000
EOF

	return 0
}

speedtest_update() {
	# do all the work to collect / calculate the values
	# for each dimension
	# remember: KEEP IT SIMPLE AND SHORT
  # Get the up and down speed. Parse them into separate values, and drop the Mbps.
  speedtest_output=$(speedtest -f json --accept-license --accept-gdpr)
  down=$(echo $speedtest_output | jq ."download.bandwidth")
  up=$(echo $speedtest_output | jq ."upload.bandwidth")
  bytesToMbits=0.000008

  down_mbytes=$( echo "$down * $bytesToMbits" | bc)
  up_mbytes=$( echo "$up * $bytesToMbits" | bc)

	# write the result of the work.
	cat <<VALUESEOF
BEGIN system.connectionspeed
SET down = $down_mbytes
SET up = $up_mbytes
END
VALUESEOF

	return 0
}
