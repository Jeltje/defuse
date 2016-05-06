FROM ubuntu:14.04

MAINTAINER Jeltje van Baren, jeltje.van.baren@gmail.com

RUN apt-get update && apt-get install -y \
        libboost-dev \
        samtools \
        git \
	bowtie \
        r-base \
        wget

WORKDIR /opt
RUN git clone https://bitbucket.org/dranew/defuse.git
WORKDIR /opt/defuse/tools
RUN make

WORKDIR /opt
RUN wget -O /usr/bin/faToTwoBit http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/faToTwoBit
RUN wget -O /usr/bin/blat http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/blat/blat
RUN chmod 775 /usr/bin/blat /usr/bin/faToTwoBit

RUN mkdir bowtie_build gmap_build

RUN wget -O /tmp/ada_2.0-3.tar.gz https://cran.r-project.org/src/contrib/ada_2.0-3.tar.gz
RUN R CMD INSTALL /tmp/ada_2.0-3.tar.gz

RUN wget http://research-pub.gene.com/gmap/src/gmap-gsnap-2015-11-20.tar.gz
RUN tar -xf gmap-gsnap-2015-11-20.tar.gz
RUN cd gmap-2015-11-20 && ./configure --disable-builtin-popcount --disable-sse4.2 && make && make install

# Set WORKDIR to /data -- predefined mount location.
RUN mkdir /data
WORKDIR /data

# Make sure the defuse script can be found
# can run defuse.pl or create_reference_dataset.pl or (after run) get_reads.pl
ENV PATH /opt/defuse/scripts/:$PATH
ADD ./wrapper.sh /opt/defuse/
ADD remove.these /opt/defuse/

ENTRYPOINT ["sh", "/opt/defuse/wrapper.sh"]
CMD ["--help"]

# And clean up
#RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* 


