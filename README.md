# quexs-docker

Docker image for queXS based on tutum/lamp


Usage
-----

To create the image `acspri/quexs`, run the following command from the checkout of this repository:

    docker build -t acspri/quexs .

Running the queXS docker image
------------------------------

Start the image, bind port 80 on all interfaces to your container:

    docker run -d -p 80:80 acspri/quexs

Access queXS by visiting:

    http://localhost/

A default username and password is created of:

    admin
    password

Notes
-----

