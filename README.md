# quexf-docker

Docker image for queXF based on tutum/lamp


Usage
-----

To create the image `acspri/quexf`, run the following command from the checkout of this repository:

docker build -t acspri/quexf .

Running the queXF docker image
------------------------------

Start the image, bind port 80 on all interfaces to your container:

    docker run -d -p 80:80 -v /location-of-forms:/forms acspri/quexf

Where /location-of-forms is a directory on your local machine that contains PDF forms for importing

Access queXF by visiting:

    http://localhost/

A default username and password is created of:

    admin
    password

To change the password - find the name of the running container:

    docker ps

then execute:

    docker exec -i -t name_of_container /usr/bin/htpasswd -B /opt/quexf/password admin


Notes
-----

queXF is configured to enable Tesseract OCR.

Images of forms are stored in the /images Volume
