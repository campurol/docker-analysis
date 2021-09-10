# First stage
FROM ubuntu:latest as install
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
COPY setup.do /home
RUN cd /home && stata -b do setup.do
RUN echo "export PATH=/usr/local/stata:${PATH}" >> /root/.bashrc

# setup stata kernel
FROM jupyter/base-notebook:latest
USER root

#updates and such
RUN apt-get update && \
    apt-get install -y autoconf automake build-essential git libncurses5 libtool make pkg-config tcsh vim zlib1g-dev && \
    wget http://archive.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng_1.2.54.orig.tar.xz && \
    tar xvf libpng_1.2.54.orig.tar.xz && \
    rm libpng_1.2.54.orig.tar.xz && \
    cd libpng-1.2.54 && \
    ./autogen.sh && \
    ./configure && \
    make -j8  && \
    make install && \
    ldconfig && \
    cd .. && \
    rm -R libpng_1.2.54.orig.tar.xz/

# install stata
COPY --from=install /usr/local/stata/ /usr/local/stata/
RUN echo "export PATH=/usr/local/stata:${PATH}" >> /root/.bashrc
ENV PATH "$PATH:/usr/local/stata" 

#install stata kernel
RUN pip install stata_kernel && python -m stata_kernel.install
RUN chmod +x ~/.stata_kernel.conf

#install python packages
RUN pip install geopy
RUN mamba install shapely pyproj rtree matplotlib descartes mapclassify contextily
RUN mamba install pytorch torchvision torchaudio cpuonly -c pytorch
RUN mamba install pandas scikit-learn numpy pysal geopandas osmnx libspatialindex=1.9.3 --channel conda-forge
#RUN mamba install beautifulsoup4 black bokeh bottleneck cartopy contextily coverage cython dill flake8 flake8-bugbear folium gdal \
#                  isort jupyterlab mapclassify nbdime nbqa nodejs numexpr osmnx pandana pillow pip psycopg2 pydocstyle pyproj pysal \
#                  pytest python == 3.9.* python-igraph rasterio seaborn scikit-learn scipy sphinx statsmodels urbanaccess 
                  
#install jupyter extensions
RUN mamba install nodejs -c conda-forge

#plotly
RUN mamba install -c plotly plotly=5.3.1
RUN mamba install -c conda-forge -c plotly jupyter-dash

##LEAFLET
RUN mamba install ipyleaflet  -c conda-forge
RUN mamba install mamba_gator -c conda-forge

##
RUN jupyter labextension install jupyterlab-stata-highlight

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
