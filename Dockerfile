FROM mambaorg/micromamba:1.5.8-noble

COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml /environment.yml

RUN micromamba install -y -n base -f /environment.yml && \
    micromamba clean --all --yes

# default install produces the following error when running in Docker:
# > library(affy)
# > library(affydata)
# > data(Dilution)
# > rma(Dilution)
# ...
# Background correcting
# Error in rma(Dilution) : ERROR; return code from pthread_create() is 22

# this is something to do with the libblas libraries being missing for
# some reason, from a running container:

# $ grep -R stuff /opt > /dev/null
# grep: /opt/conda/pkgs/libcblas-3.9.0-23_linux64_openblas/lib/libcblas.so.3: No such file or directory
# grep: /opt/conda/pkgs/libcblas-3.9.0-23_linux64_openblas/lib/libcblas.so: No such file or directory
# grep: /opt/conda/pkgs/libblas-3.9.0-23_linux64_openblas/lib/libblas.so.3: No such file or directory
# grep: /opt/conda/pkgs/libblas-3.9.0-23_linux64_openblas/lib/libblas.so: No such file or directory
# ...

# you can recompile preprocessCore, where the error originates, to avoid using pthreads
# no idea why, but if you reinstall preprocessCore TWICE (not once) the
# error goes away...
RUN micromamba run -n base R -e 'BiocManager::install("preprocessCore", configure.args="--disable-threading", force = TRUE)'
RUN micromamba run -n base R -e 'BiocManager::install("preprocessCore", configure.args="--disable-threading", force = TRUE)'

USER 0
RUN mkdir -p /src

WORKDIR /src
