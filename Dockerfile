# NOTE: Modified from Dan Nixon's Dockerfiles - https://github.com/DanNixon/docker-mantiddev
FROM ubuntu:bionic

# Needed to allow install of tzdata
ENV DEBIAN_FRONTEND noninteractive

ENV MANTID_GIT_REPO    /root/mantid
ENV MANTIDBRANCH       master
ENV BUILD_DIR          build-${MANTIDBRANCH}
ENV MANTIDPATH         ${MANTID_GIT_REPO}/build-${MANTIDBRANCH}/bin
ENV MANTID_TS_GIT_REPO /root/mantid_total_scattering
ENV MANTID_TS_PATH     ${MANTID_TS_GIT_REPO}
ENV PATH               ${MANTIDPATH}:${PATH}
ENV PYTHONPATH         ${MANTIDPATH}:${MANTID_TS_PATH}:${PYTHONPATH}
ENV PYTHON_EXE         /usr/bin/python3

RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y byobu curl git htop man unzip vim wget && \
  apt-get install equivs -y && \
  apt-add-repository ppa:mantid/mantid -y && \
  rm -rf /var/lib/apt/lists/*

RUN apt-get update
RUN apt-get --yes --force-yes install gdebi-core


# Build and install the developer package
RUN wget -O - https://raw.githubusercontent.com/mantidproject/mantid/master/buildconfig/dev-packages/deb/mantid-developer/ns-control | equivs-build - && \
    gdebi --non-interactive mantid-developer_*.deb

# Install Python 3 dependencies (see http://developer.mantidproject.org/Python3.html)
RUN apt-get install -y python3-sip-dev python3-pyqt4  python3-numpy  python3-scipy  python3-sphinx \
    python3-sphinx-bootstrap-theme  python3-dateutil python3-matplotlib ipython3-qtconsole \
    python3-h5py python3-yaml

# Install static analysis dependencies
RUN pip install flake8==2.5.4 pep8==1.6.2 pyflakes==1.3.0 mccabe==0.6.1 && \
    apt-get install -y cppcheck

# Install Mantid
RUN cd /root && \
    git clone https://github.com/mantidproject/mantid && \
    cd ${MANTID_GIT_REPO} && \
    git checkout ${MANTIDBRANCH} && \
    mkdir ${BUILD_DIR} && \
    cd ${BUILD_DIR} && \
    cmake -GNinja -DPYTHON_EXECUTABLE=$PYTHON_EXE $MANTID_GIT_REPO && \
    ninja

# Install mantid_total_scattering
RUN cd /root && \
    git clone https://github.com/marshallmcdonnell/mantid_total_scattering.git
