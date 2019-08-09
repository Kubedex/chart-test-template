# chart-test-template

Clone this repo as a starting point for any new Helm Chart you'd like to create. This template supports one chart per repo.

Delete the `grafana` directory which is used as an example.

Create a new chart by running `helm create chartname`.

When ready to test you can run `make`. This will start a K3s docker container, install helm and tiller, and execute `helm upgrade --install` on your chart directory.

By default `make` will also run `helm lint` and `helm test` on your installed chart.

You can leave the K3s docker container running and continue to iterate installation and tests by running `make chart` to upgrade the chart and `make lint` and `make test`.

To remove the chart from a running container use `make chartrm`. You can then install cleanly again using `make chart`.

To kill everything and start from scratch including terminating the K3s container use `make clean`.

# Tests

We execute `helm test` inside the docker container against the release that was installed. This runs the tests defined in `chartname/templates/tests`. The Grafana chart included in this repo has some good examples that you can read.

# Local chart value overrides

Sometimes it's useful to override the values.yaml for local testing. Put any overrides into the `values.yaml` in the root of this repo.

# Gotchas

The `Makefile` works out the name of the chart based up directories that exist in the repo. If you add more directories you'll need to exclude them.

For example to exclude a `ci` and `docs` directory that you want to add update this line in the `Makefile`.

```
CHARTNAME := $(shell ls -1d */ | sed 's\#/\#\#' | grep -v 'tools\|ci\|docs')
```
