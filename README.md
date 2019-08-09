# chart-test-template

Clone this repo as a starting point for any new Helm Chart you'd like to create. This template supports one chart per repo.

[![asciicast](https://asciinema.org/a/1HFqI8780RKjODUVsKcTRMiP0.svg)](https://asciinema.org/a/1HFqI8780RKjODUVsKcTRMiP0)

Delete the `grafana` directory which is used as an example.

Create a new chart by running `helm create chartname`.

When ready to test you can run `make`. This will start a K3s docker container, install helm and tiller, and execute `helm upgrade --install` on your chart directory.

By default `make` will also run `helm lint` and `helm test` on your installed chart.

You can leave the K3s docker container running and continue to iterate installation and tests by running `make chart` to upgrade the chart and `make lint` and `make test`.

To remove the chart from a running container use `make chartrm`. You can then install cleanly again using `make chart`.

To investigate chart problems you can run `make ssh` to log into the K3s container and run the usual `kubectl` and `helm` commands to troubleshoot.

To kill everything and start from scratch including terminating the K3s container use `make clean`.

# Tests

We execute `helm test` inside the docker container against the release that was installed. This runs the tests defined in `chartname/templates/tests`. The Grafana chart included in this repo has some good examples that you can read.

# Local chart value overrides

Sometimes it's useful to override the values.yaml for local testing. Put any overrides into the `values.yaml` in the root of this repo.

# Gotchas

The `Makefile` works out the name of the chart based upon directories that exist in the repo. If you add more directories you'll need to exclude them.

For example to exclude a `ci` and `docs` directory that you want to add update this line in the `Makefile`.

```
CHARTNAME := $(shell ls -1d */ | sed 's\#/\#\#' | grep -v 'tools\|ci\|docs')
```

# Using with ECR

Change the `REGISTRYID` and `REGISTRYREGION` variable at the top of the `Makefile`.

Before running `make` ensure you have the correct AWS credentials set that allow the `aws ecr get-login` command to work.

We copy `tools/imagepullsecret.sh` into the k3s container and execute it so it creates a pull secret called `aws-registry` in the same namespace that the chart is installed into.

We also set `imagePullSecrets: ["aws-registry"]` in the values.yaml in the root of the repo so that this is only applied to charts when run under K3s and not when deployed to AWS clusters that will use an IAM role.

Finally, inside your chart you will need to add the following to your template. Under `spec.template.spec` add.

```
      {{- if .Values.imagePullSecrets }} 
      imagePullSecrets:
      {{- range $sec := .Values.imagePullSecrets }}
        - name: {{$sec | quote }}
      {{- end }}
      {{- end }}
```

This sets the imagePullSecret if the value is set.
