#!/bin/bash -eu
# 
# This script will try to configure/deploy an ELK stack into cloud.gov
# 
KIBANA_VERSION=5.6.8
LOGSTASH_VERSION=5.6.8

############################################
# Start up kibana here
if cf services | grep OK >/dev/null ; then
	echo cf seems to be up and going.
	echo This deploy will be going into:
	cf target
else
	echo cf seems not to be logged into an org/space
	echo "please log in now with 'cf login -a api.fr.cloud.gov --sso'"
	exit 1
fi

if [ -d kibana ] ; then
	echo kibana seems to be checked out already.  Leaving alone.
else
	git clone -b "v${KIBANA_VERSION}" --single-branch --depth 1 https://github.com/elastic/kibana.git
fi

cp run_kibana.sh server.js package.json kibana/

if cf services | grep ^elk-elasticsearch >/dev/null ; then
	echo elk-elasticsearch seems to be set up already, leaving alone
else
	cf create-service elasticsearch56 medium elk-elasticsearch
	until cf services | grep 'elk-elasticsearch.*create succeeded' >/dev/null ; do
		echo sleeping until elasticsearch service is provisioned...
		sleep 5
	done
fi

cf push -f kibana-manifest.yml
export ES_URI=$(cf env elk-kibana | grep '    "uri' | sed 's/.*\(http.*\)".*/\1/')
export ES_URL=$(echo "${ES_URI}" | sed 's/\/\/.*@/\/\//')
export ES_USER=$(echo "${ES_URI}" | sed 's/.*\/\/\(.*\):.*@.*/\1/')
export ES_PW=$(echo "${ES_URI}" | sed 's/.*\/\/.*:\(.*\)@.*/\1/')


############################################
# Start up logstash here
cf push -f logstash-manifest.yml --no-start -o docker.elastic.co/logstash/logstash:"${LOGSTASH_VERSION}"
cf set-env elk-logstash XPACK.MONITORING.ENABLED false
cf set-env elk-logstash XPACK.SECURITY.ENABLED false
# XXX probably should set some creds or a router that filters up here, so that 
# XXX people can't just shove stuff into logstash from the outside world.
cf set-env elk-logstash CONFIG_STRING "$(cat <<EOF
output {
	elasticsearch {
		hosts => ["${ES_URL}"]
		user => "${ES_USER}"
		password => "${ES_PW}"
	}
}
input {
	tcp {
		port => 5000
		type => syslog
	}
	udp {
		port => 5000
		type => syslog
	}
}
EOF
)"
cf push -f logstash-manifest.yml -o docker.elastic.co/logstash/logstash:"${LOGSTASH_VERSION}"

## set logstash service up for our space to drain logs into
## XXX need to figure out how to get network-policy stuff to work so we can connect directly to 5000
## XXX Either that, or 
# LOGSTASH_URL="syslog://$(cf app elk-logstash | awk '/^routes/ {print $2}'):5000"
# cf create-user-provided-service elk-logstash -l "${LOGSTASH_URL}"
# cf bind-service elk-kibana elk-logstash
# cf bind-service elk-logstash elk-logstash
# cf restage elk-kibana
# cf restage elk-logstash

# load some data into logstash
# If we already loaded data in, then don't do it again.
if [ $(cf ssh elk-logstash -c "curl -s '${ES_URI}/logstash-*/_count'" | jq .count) = "0" ] ; then
	cf ssh elk-logstash -c "curl -XPUT '${ES_URI}/shakespeare?pretty' -H 'Content-Type: application/json' -d'
	{
	 \"mappings\": {
	  \"doc\": {
	   \"properties\": {
	    \"speaker\": {\"type\": \"keyword\"},
	    \"play_name\": {\"type\": \"keyword\"},
	    \"line_id\": {\"type\": \"integer\"},
	    \"speech_number\": {\"type\": \"integer\"}
	   }
	  }
	 }
	}
	'"
	cf ssh elk-logstash -c "curl -XPUT '${ES_URI}/logstash-2015.05.18?pretty' -H 'Content-Type: application/json' -d'
	{
	  \"mappings\": {
	    \"log\": {
	      \"properties\": {
	        \"geo\": {
	          \"properties\": {
	            \"coordinates\": {
	              \"type\": \"geo_point\"
	            }
	          }
	        }
	      }
	    }
	  }
	}
	'"
	cf ssh elk-logstash -c "curl -XPUT '${ES_URI}/logstash-2015.05.19?pretty' -H 'Content-Type: application/json' -d'
	{
	  \"mappings\": {
	    \"log\": {
	      \"properties\": {
	        \"geo\": {
	          \"properties\": {
	            \"coordinates\": {
	              \"type\": \"geo_point\"
	            }
	          }
	        }
	      }
	    }
	  }
	}
	'"
	cf ssh elk-logstash -c "curl -XPUT '${ES_URI}/logstash-2015.05.20?pretty' -H 'Content-Type: application/json' -d'
	{
	  \"mappings\": {
	    \"log\": {
	      \"properties\": {
	        \"geo\": {
	          \"properties\": {
	            \"coordinates\": {
	              \"type\": \"geo_point\"
	            }
	          }
	        }
	      }
	    }
	  }
	}
	'"
	cf ssh elk-logstash -c 'curl -o shakespeare_6.0.json https://download.elastic.co/demos/kibana/gettingstarted/shakespeare_6.0.json'
	cf ssh elk-logstash -c 'curl -o logs.jsonl.gz https://download.elastic.co/demos/kibana/gettingstarted/logs.jsonl.gz'
	cf ssh elk-logstash -c 'gunzip logs.jsonl.gz'
	cf ssh elk-logstash -c 'mkdir shakespearetmp ; cd shakespearetmp ; split -l 100 ../shakespeare_6.0.json'
	cf ssh elk-logstash -c 'mkdir logstmp ; cd logstmp ; split -l 100 ../logs.jsonl'
	cf ssh elk-logstash -c "cd shakespearetmp ; for i in * ; do curl -H 'Content-Type: application/x-ndjson' -XPOST '${ES_URI}/shakespeare/doc/_bulk?pretty' --data-binary @\$i ; done"
	cf ssh elk-logstash -c "cd logstmp ; for i in * ; do curl -H 'Content-Type: application/x-ndjson' -XPOST '${ES_URI}/_bulk?pretty' --data-binary @\$i ; done"
fi

# let folks know how to get in:
KIBANA_URL=$(cf apps | grep elk-kibana | awk '{print $6}')
echo "##########################################"
echo "Kibana username: ${ES_USER}"
echo "Kibana password: ${ES_PW}"
echo "Kibana URL: ${KIBANA_URL}"
echo "##########################################"
