# setup stata kernel
FROM jupyter/base-notebook:latest
USER root
RUN apt-get update && \
    apt-get install -y autoconf automake build-essential git libncurses5 libtool make pkg-config tcsh vim zlib1g-dev && \
    wget http://archive.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng_1.2.54.orig.tar.xz && \
    tar xvf  libpng_1.2.54.orig.tar.xz && \
    cd libpng-1.2.54 && \
    ./autogen.sh && \
    ./configure && \
    make -j8  && \
    make install && \
    ldconfig
    
# install stata
COPY stata_install.tar.gz /home/stata_install.tar.gz
RUN cd /tmp/ && \
    mkdir -p statafiles && \
    cd statafiles && \
    tar -zxf /home/stata_install.tar.gz && \
    cd /usr/local && \
    mkdir -p stata && \
    cd stata && \
    yes | /tmp/statafiles/install
COPY stata.lic /usr/local/stata
RUN stata -b update all &
RUN rm -r /tmp/statafiles/
RUN rm /home/stata_install.tar.gz

#install stata from other image
ENV PATH="/usr/local/stata:$PATH"

#install stata kernel
RUN pip install stata_kernel && python -m stata_kernel.install
RUN chmod +x ~/.stata_kernel.conf

#install python packages
RUN pip install geopy
RUN mamba install pandas scikit-learn numpy --channel conda-forge
RUN mamba install pytorch torchvision torchaudio cpuonly -c pytorch
RUN mamba install pysal geopandas libspatialindex=1.9.3 --channel conda-forge
RUN mamba install shapely pyproj rtree matplotlib descartes mapclassify contextily

#install jupyter extensions
RUN mamba install -c plotly plotly=5.3.1
RUN mamba install -c conda-forge -c plotly jupyter-dash

##LEAFLET
RUN mamba install ipyleaflet  -c conda-forge
RUN mamba install mamba_gator -c conda-forge

##
RUN jupyter lab build

#CLEANING UP
###
RUN apt-get remove pkg-config -y

#JUPYTER PASSWORD
ENV JUPYTER_TOKEN=my_secret_token
RUN echo "c.NotebookApp.password='sha1:6b5076404aea:d8938059746229331a568de8bd9223825ec11fa9'">>/home/jovyan/.jupyter/jupyter_notebook_config.py

#Time Zone
RUN apt-get install -y tzdata
ENV TZ=America/Toronto
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#RUN COMMAND
WORKDIR /home/
CMD ["jupyter", "lab", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root"]
