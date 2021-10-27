# docker/es5 support

This dockerfile exists to make it easier to test that things still work in an es5 environment, as that is still fairly common (notably Solaris, but also ubuntu 18.04 LTS and RHEL 7).

From the root directory of jsonvalidate source, run

```
docker build --tag richfitz/jsonvalidate:es5 docker
```

to build the image; this should not take that long. It installs the current r-release along with the CRAN versions of jsonvalidate and testthat (which ensures all core dependencies are present).

Once setup, you can bring up a container with:

```
docker run --rm -it -v $PWD:/src:ro richfitz/jsonvalidate:es5 bash
```

which mounts the current directory read-only into the container at `/src`.  That version of the source (rather than the CRAN one installed in the base image) can be installed with `R CMD INSTALL /src`

To run the whole test suite run:

```
Rscript -e 'testthat::test_local("/src")'
```

More simply, to just confirm that the bundle is valid you can do

```
Rscript -e 'V8::new_context()$source("/src/inst/bundle.js")'
```

which will error if the bundle is invalid.

To do a full reverse dependencies check with old libv8, you can bring up R in this container:

```
docker run --rm -it -v $PWD:/src:ro richfitz/jsonvalidate:es5 bash
```

Then install revdepcheck itself

```
install.packages("remotes")
remotes::install_github("r-lib/revdepcheck", upgrade = TRUE)
```

Additional packages that we need, for some reason these did not get installed automatically though we'd have expected them to (see [this issue](https://github.com/r-lib/revdepcheck/issues/209))

```
install.packages(c(
  "cinterpolate",
  "deSolve",
  "devtools",
  "golem",
  "inTextSummaryTable",
  "patientProfilesVis",
  "reticulate",
  "rlist",
  "shiny",
  "shinyBS",
  "shinydashboard",
  "shinyjs",
  "tableschema.r",
  "xml2"))
```

At this point you will need to cycle the R session because the package DB will be corrupted by all the installations.

Finally we can run the reverse dependency check:

```
unlink("/tmp/src", recursive = TRUE)
file.copy("/src", "/tmp", recursive = TRUE)
revdepcheck::revdep_check("/tmp/src", num_workers = 4)
```
