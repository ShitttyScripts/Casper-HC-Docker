# Casper-HC-Docker

Deploy [Casper HC](https://github.com/jamfit/Casper-HC) with Docker-Compose

> `docker-compose.yml` uses file version 3 syntax which is supports by Docker Engine 1.13.0+. Update your [Docker Toolbox](https://www.docker.com/products/docker-toolbox) to ensure you have the latest versions.

## Deploying Casper-HC

### Configuration

The application uses a combination of environment variables and files to confgure itself upon building.

> Be sure you are working in the repository's directory.

#### MySQL

Both the `mysql` and `web` services require a file that contains the values needed for the database connection. The file should be formatted as such:

```
MYSQL_SERVER=mysql
MYSQL_ROOT_PASSWORD=xxxxx
MYSQL_DATABASE=xxxxx
MYSQL_USER=xxxxx
MYSQL_PASSWORD=xxxxx
```

> Be sure **`MYSQL_SERVER`** is set to **`mysql`** as this will be the container's name on the local Docker network.

Save this file within the root of the repository and set the environment variable that contains the filename:

```shell
~$ export MYSQL_ENV_FILE=example_mysql
```

#### Flask

The application requires a config file that will be loaded into the Docker image at build time. The file should be formatted as such (Python syntax):

```python
DEBUG = True  # bool (default is False)
SERVER_DOMAIN = 'casper.example.com'
DATABASE_KEY = '\xd7M\xdcK\n\xe2\xbb5\x8c\x9e\x88\x1bn\xae\xa2D'
SECRET_KEY = '_\x11"k\x9f\x94\xee]\xe6\xfa\xaa\x7f\xc4Z\xec\x13'
```

Generate random bytes for the values of the `DATABASE_KEY` and `SECRET_KEY`.

The `DATABASE_KEY` is used to encrypt saved service accounts in the database.

The `SECRET_KEY` is used to secure active sessions by enabling cookie signing.

*(see [Flask: Sessions](http://flask.pocoo.org/docs/0.12/quickstart/#sessions))*

The following code will produce sufficiently random keys:

```
>>> import os
>>> os.urandom(32)
'\xfc\x86\x7f=\xc53\xfbyA\x08\x91\xb5\x03\xff\x8d+s\xdc\xd4\xb79\x17\x82\xb4\x94\x7f\x14.\xc0\xd8KL'
>>>
```

Save this file within the root of the repository and set the environment variable that contains the filename:

```shell
~$ export FLASK_CONFIG_FILE=example_flask
```

#### Set the Git Branch to Build From

You will need to set a final environment variable that contains the name of the branch or tag (version) that will be pulled from GitHub when building the image.

* `master` (stable release)
* `development` (latest commit, potentially unstable)
* `v0.1.0` (specific tag/version)

```shell
~$ export BRANCH=master
```

### Deploy to Docker Engine

Connect to a running Docker Engine using `docker-machine`:

```shell
~$ eval $(docker-machine env my-docker-vm)
```

Build the images:

```shell
~$ docker-compose build
```

> If you encounter errors in the build process, review the output. You may have missed properly setting an environment variable or filename.

Start the containers:

```shell
~$ docker-compose up -d
```

The `mysql`, `web` and `nginx` containers should now be running. If you go to the IP address of the VM in your browser you should see the following message:

![Screenshot](/images/app-running.png)

### Create the Database

Start a shell on the `web` service, `cd` to the application directoty and then launch Python:

```shell
~$ docker exec -it web bash
root@xxxxx:/$ cd /opt/web-app/
root@xxxxx:/opt/web-app$ python
```

RUn the commands below to create the initial database.

```python
>>> from casper import db
>>> db.create_all()
>>>
```

*(Optional)* To use Flask-Migrate's migration feature for future updates, initialize a migration repository with the following command in the application directory:

```shell
root@xxxxx:/opt/web-app$ manage_db.py db init
```

*See the [Flask-Migrate docs](https://flask-migrate.readthedocs.io/en/latest/) for more details.*

## Testing

To test the application, use a tunneling service such as [ngrok](https://ngrok.com/) to make the VM accessible to the internet. Use the IP address of the VM in the following command:

```
~$ ngrok http xxx.xxx.xxx.xxx:80 --bind-tls true
```

A randomized URL will be made available that tunnels traffic from port `443` through a secure tunnel to port `80` on the VM.

See [Start a ngrok tunnel](https://developer.atlassian.com/hipchat/tutorials/getting-started-with-atlassian-connect-express-node-js#Gettingstartedwithatlassian-connect-express(Node.js)-Startangroktunnel) for more details.

## Production

If you are deploying the application to production you must secure it with a TLS cert.

You can modify the `docker-compose.yml` and `nginx/web-app.conf` files to deploy the required configuration depending upon your environment.

A potential solution is to store the certificate and key file on the host VM and mount that directory into the `nginx` container. Modify make the following change to `docker-compose.yml` to do this:

```yaml
nginx:
    ...
    volumes:
      - /etc/ssl/certs/web-app:/etc/ssl/certs/web-app
    ...
```

Next modify `nginx/web-app.conf` to point to those files and enable TLS:

```nginx
upstream flask {
    server web:5000;
}

server {
    listen 80;
    server_name $host;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name $host;

    ssl_certificate /etc/ssl/certs/web-app/server.crt;
    ssl_certificate_key /etc/ssl/certs/web-app/server.key;

    location / {
        include uwsgi_params;
        uwsgi_pass flask;
    }
}
```

## Install to a HipChat Room

The application's capabilities descriptor will be reachable at:

```
https://{host}/hipchat/capabilities
```

See [Install the add-on in HipChat](https://developer.atlassian.com/hipchat/tutorials/getting-started-with-atlassian-connect-express-node-js#Gettingstartedwithatlassian-connect-express(Node.js)-Installtheadd-oninHipChat) for more detailed instructions on how to manually install the application.

### Configure Jamf Pro Service Account

> A service account is only required for enabling the search features of the plugin. Notifications can be used without adding a service account.

From the configuration page you may enter a Jamf Pro URL with a username and password for a service account to enable the plugin to perform API requests.

![Screenshot](/images/configure.png)
