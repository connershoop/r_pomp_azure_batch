# Set the R version
ARG VERSION=4.4.1

# Use the official R base image
FROM r-base:${VERSION}

# Set the working directory inside the container
WORKDIR /app

# Install R packages with multiple CPUs
RUN Ncpus=$(grep -c ^processor /proc/cpuinfo) \
    && R -e "install.packages(c('pomp', 'subplex', 'subplex', 'plyr', 'magrittr', 'zoo', 'FME'), Ncpus = $Ncpus, repos='http://cran.rstudio.com/')"