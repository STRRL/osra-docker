# syntax=docker/dockerfile:experimental

FROM openjdk:8 AS build

#installing build tools
RUN \
	apt-get update && \
	apt-get install -y build-essential automake checkinstall git cmake subversion

#fetching source codes
RUN \
	cd /tmp && \
	git clone https://github.com/metamolecular/gocr-patched.git && \
	svn checkout svn://svn.code.sf.net/p/osra/code/tags/2.1.3 /tmp/osra

#installing dependencies for osra
RUN \
	apt-get install -y libtclap-dev libpotrace0  libpotrace-dev  libocrad-dev libgraphicsmagick++1-dev libgraphicsmagick++1-dev libgraphicsmagick++3 && \
	apt-get install -y libeigen3-dev libgraphicsmagick1-dev libgraphicsmagick-q16-3 libnetpbm10-dev libpoppler-dev libpoppler-cpp-dev libleptonica-dev wget tesseract-ocr tesseract-ocr-eng

# install patched openbabel 
RUN \
	wget -q https://github.com/STRRL/osra-docker/releases/download/bucket/openbabel-3-0-0-patched.tgz -O /tmp/openbabel-3-0-0-patched.tgz && \
	tar zxvf /tmp/openbabel-3-0-0-patched.tgz --directory=/tmp && \
	cd /tmp/openbabel-3-0-0-patched && \
	mkdir build && \
	cd build && \
	cmake .. && \
	make -j 16 && \
	make install

#patching gocr
RUN \
	cd /tmp/gocr-patched && \
	./configure && \
	make libs && \
	make all install

#installing osra
RUN \
	cd /tmp/osra && \
	./configure --with-tesseract && \
	make all && \
	make install && \
	echo export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib >> ~/.bashrc

#useful converter
RUN \
	apt-get install -y imagemagick

#cleanup
RUN rm -rf /var/lib/apt/lists/*
RUN rm -rf /tmp/*

CMD ["bash"]


FROM debian:bullseye
LABEL org.opencontainers.image.source=https://github.com/STRRL/osra-docker

MAINTAINER Gert wohlgemuth <wohlgemuth@ucdavis.edu>
MAINTAINER STRRL <im@strrl.dev>

RUN \
	apt update && \
	apt-get install -y wget libtclap-dev libpotrace0 libpotrace-dev libocrad-dev libgraphicsmagick++1-dev libgraphicsmagick++1-dev libgraphicsmagick++3 libeigen3-dev libgraphicsmagick1-dev libgraphicsmagick-q16-3 libnetpbm10-dev libpoppler-dev libpoppler-cpp-dev libleptonica-dev tesseract-ocr tesseract-ocr-eng && \
	rm -rf /var/lib/apt/lists/*

RUN echo export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib >> ~/.bashrc

COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /usr/local/bin/osra /usr/local/bin/osra
COPY --from=build /usr/local/share /usr/local/share

CMD ["bash"]
