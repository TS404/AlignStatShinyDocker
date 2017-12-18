# "ported" by Adam Miller <maxamillion@fedoraproject.org> from
#   https://github.com/fedora-cloud/Fedora-Dockerfiles
#
# Originally written for Fedora-Dockerfiles by
#   "Scott Collier" <scollier@redhat.com>
#   
# Taken from https://github.com/CentOS/CentOS-Dockerfiles/tree/master/httpd/centos7
# by Benji Wakely <b.wakely@latrobe.edu.au>, 20150116

# "supervisor"-ness taken from http://tiborsimko.org/docker-running-multiple-processes.html

# After build / for first-run setup, see /data/docker/shiny/READTHIS for steps
# relating to mounting host-directories for persistence,
# changing permissions on those directories etc.

# Use for standalone builds
FROM centos:latest

#FROM docker-io-centos-with-ssh:latest
LABEL maintainer Benji Wakely <b.wakely@latrobe.edu.au>

RUN yum install -y epel-release

RUN yum update -y

RUN yum install -y cmake \
					make \
					gcc \
					g++ \
					git \
					hostname \
					openssh-server \
					supervisor \
                    wget \
                    openssl-devel libcurl-devel



RUN yum install -y R && \
	yum clean all

RUN groupadd -g 600 shiny && useradd -u 600 -g 600 -r -m shiny

# Note: /var/log/shiny-server needs to be mounted from the host at run-time, so creating it here
# won't actually do anything.  But just in case the build process needs it...
RUN mkdir -p /var/log/shiny-server /srv/shiny-server /var/lib/shiny-server /etc/shiny-server && \
	chown -R shiny /var/log/shiny-server

RUN R -e "install.packages('shiny', repos='https://cran.rstudio.com/')"

RUN wget https://download3.rstudio.org/centos5.9/x86_64/shiny-server-1.5.3.838-rh5-x86_64.rpm
RUN yum install -y --nogpgcheck shiny-server-1.5.3.838-rh5-x86_64.rpm

RUN mkdir -p /usr/share/doc/R-3.4.0/html/ 

RUN R -e "install.packages(c('rmarkdown'), repos='https://cran.rstudio.com/')"

RUN R -e "install.packages(c('devtools'), repos='https://cran.rstudio.com/')"

RUN R -e 'devtools::install_github("ts404/AlignStat")'

RUN wget https://github.com/ts404/AlignStatShiny/archive/v0.1.1.zip && \
    unzip v0.1.1.zip && \
    mkdir -p /srv/shiny-server/alignstat && \
    cp AlignStatShiny-0.1.1/*.R /srv/shiny-server/alignstat/

# This is the port that the docker container expects to recieve communications on.
# 
EXPOSE 3838


# Already done in the parent container.
# If modifying this dockerfile to generate a standalone container,
# please touch / create '/etc/supervisord.conf'
RUN echo "[supervisord]" > /etc/supervisord.conf && \
    echo "nodaemon=true" >> /etc/supervisord.conf && \
    echo "" >> /etc/supervisord.conf >> /etc/supervisord.conf

# The above is already set up in the base image, centos-with-ssh:latest
COPY shiny-server.conf /etc/shiny-server/

RUN echo "[program:shiny]" >> /etc/supervisord.conf && \
    echo "command=/usr/bin/bash -c '/usr/bin/shiny-server'" >> /etc/supervisord.conf

CMD ["/usr/bin/supervisord"]
