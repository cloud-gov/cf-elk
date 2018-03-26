#!/bin/bash

export ES_URI=$(echo "${VCAP_SERVICES}" | jq -r .elasticsearch56[0].credentials.uri)
export ES_URL=$(echo "${ES_URI}" | sed 's/\/\/.*@/\/\//')
export ES_USER=$(echo "${ES_URI}" | sed 's/.*\/\/\(.*\):.*@.*/\1/')
export ES_PW=$(echo "${ES_URI}" | sed 's/.*\/\/.*:\(.*\)@.*/\1/')

if grep ^elasticsearch.url config/kibana.yml >/dev/null ; then
	echo kibana.yml is already configured
else
	echo "elasticsearch.url: \"${ES_URL}\"" >> config/kibana.yml
	echo "server.port: \"${PORT}\"" >> config/kibana.yml
	#echo "logging.verbose: true" >> config/kibana.yml
	echo "logging.verbose: true" >> config/kibana.yml
	echo "elasticsearch.username: \"${ES_USER}\"" >> config/kibana.yml
	echo "elasticsearch.password: \"${ES_PW}\"" >> config/kibana.yml
	echo "server.host: \"0.0.0.0\"" >> config/kibana.yml

	echo "kibana credentials: ${ES_USER} ${ES_PW}"
fi

# start the app up.  It takes a long time to start.
./bin/kibana
