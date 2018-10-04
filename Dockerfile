FROM rocker/tidyverse

# Install Ubuntu dependencies
RUN apt-get update && apt-get install -y \
    sudo \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcairo2-dev \
    libxt-dev \
    git-core \
    libssl-dev \
    libcurl4-gnutls-dev \
    libudunits2-dev \
    libgeos-dev \
    libgdal-dev \
    gdal-bin \
    curl

# Copy project over
COPY . /srv/shiny-server/atl_salary_data

# Read download url from text file
# and download Shiny image
RUN curl -o shiny-server.deb \
  $(cat /srv/shiny-server/atl_salary_data/download-shiny-url.txt)

# Install Shiny server
RUN gdebi -n shiny-server.deb && \
    rm -f shiny-server.deb && \
    R -e "install.packages('shiny')" && \
    cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/ && \
    rm -rf /var/lib/apt/lists/*

# Install R packages
RUN install2.r --error \
	--deps TRUE \
	shinythemes \
  plotly

# Shiny port
EXPOSE 3838

# Activate Shiny server
CMD ["/srv/shiny-server/atl_salary_data/shiny-server.sh"]
