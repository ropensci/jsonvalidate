# docker/es5 support

This dockerfile exists to make it easier to test that things still work in an es5 environment, as that is still fairly common (notably Solaris, but also ubuntu 18.04 LTS and RHEL 7).

From the root directory of jsonvalidate source, run

```
docker build --tag richfitz/jsonvalidate:es5 docker
```

to build the image; this should not take that long. It installs the most recent copy of R for 18.04 (currently 3.4.4) and we should probably update this to use a ppa and get a recent copy.

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
