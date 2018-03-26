# ELK for cloud.gov

This repository contains minimal ELK stack for testing deployment to [cloud.gov](https://www.cloud.gov/), in particular, and other instances of [Cloud Foundry](https://www.cloudfoundry.org) ("CF") in general.
 
For [cloud.gov](https://cloud.gov), follow the [quickstart guide](https://cloud.gov/quickstart/) for a guided tour, or follow the USAGE below.

## Usage

1. Follow the [Cloud Foundry command-line (CLI) setup instructions](https://docs.cloudfoundry.org/cf-cli/install-go-cli.html).
1. Log into your Cloud Foundry account. (For example, if you use cloud.gov, follow [the "Set up the command line" instructions](https://cloud.gov/docs/getting-started/setup/#set-up-the-command-line) to log in.)
1. Clone or download this repository, and `cd` into the directory `cf-elk`.
1. run the deploy script with `./deploy.sh`.  It should:
    2. Clone the kibana repo with a specific version that we tested out.
    2. Copy in config that updates the node version to the latest (as of this writing) version that is compatible with kibana.
    2. Copies in a special startup script that we use to configure kibana at runtime to use the ES service we created above.
    2. Create an elasticsearch service for you.
    2. Deploys kibana with `cf push`
    2. Configures and launches the elk-logstash docker instance
    2. Sets up the internal service that can be used to drain logs into.
    2. Loads some sample data into ES.  This may take a while.
1. Get the username/password/URL that you will need to use to log into kibana from the end of the output of the script.
1. Go to the URL.  You may need to wait a bit here for kibana to fully launch.
1. You may now set a default index (probably @timestamp) and start searching!  Be aware that the data is kind of old, so you might need to set the search scope to be the last 5 years rather than the last 15 minutes.
1. There is a logstash instance living on the `elk-logstash` app URL.  You should be able to configure filebeat to send logs to it like so:
```
output.logstash:
  hosts: ["elk-logstash-<whatever>.app.cloud.gov:443"]
  ssl: true
```

## See also

* [Cloud Foundry community collection of sample applications](https://github.com/cloudfoundry-samples) 
* [cloud.gov Java Spring Boot example](https://github.com/18F/cf-sample-app-spring): This doesn't require `gradle` or any other dependencies.
* [cloud.gov Drupal example](https://github.com/18F/cf-ex-drupal)
* [cloud.gov Wordpress example](https://github.com/18F/cf-ex-wordpress)

## Public domain

This project is in the worldwide [public domain](LICENSE.md). As stated in [CONTRIBUTING](CONTRIBUTING.md):

>This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
>All contributions to this project will be released under the CC0
>dedication. By submitting a pull request, you are agreeing to comply
>with this waiver of copyright interest.
