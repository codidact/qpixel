# Docker Installation

A [docker-compose.yml](../docker-compose.yml) file is provided for deployment with Docker Compose. If you want to use a custom one, simply override the `COMPOSE_FILE` predefined environment variable in the `.env` file in project root ([local-setup.sh](./local-setup.sh) script creates one automatically from [compose-env](./compose-env). By default, `COMPOSE_FILE` is set to [docker-compose.yml](../docker-compose.yml)).

To use Docker Compose, you need to install the docker-compose-plugin. 
You can check if it's already installed via the following command:

```bash
sudo docker compose version
```

If the version is 2.x or higher, you are all set. If not, you should install the plugin. On a Debian-based Linux distro, you can run the following:

```bash
sudo apt-get install docker-compose-plugin
```

For Mac OS, you can install Docker Desktop by downloading it from the Docker website. After starting the application, the docker compose command becomes available in your terminal.

Depending on your setup, you may need to prefix every docker command with sudo.

## 1. Setup and Secrets

The `docker-compose.yml` file uses a `.env` file in the same directory to load dynamic values used when the docker containers are initialized.

This is useful for setting up custom values locally. Additionally, your secrets (the mysql database credentials and admin user name) are inserted into the running container through the `docker/env` file.

Both the `.env` file and the `docker/env` file are gitignored, so you can change values to suit. These files need to be copied to the correct locations with some default values. You can do this in one step by executing a bash script.

```bash
# ensure script is executable, from the project root:
chmod +x docker/local-setup.sh
docker/local-setup.sh
```

Editing the `./.env` file will modify the corresponding variables used in the docker-compose.yml file but **NOT** the environment variables in the container. 
Editing the `./docker/env` file will change environment variables only in the running container.

### Custom build config

Our Docker setup supports custom build configurations for the uwsgi contianer via the `CLIENT_DOCKERFILE` environment variable (see [compose-env](/docker/compose-env)). The default is `docker/Dockerfile`, which points to a preconfigured [production-like setup](/docker/Dockerfile). For developers who need more control over their setup, we also provide a [configuration](/docker/Dockerfile.dev) that is tailored for local development.

To use a custom build config, change the `CLIENT_DOCKERFILE` variable in the .env file that is automatically created by [local-setup.sh](/docker/local-setup.sh) in the project root.

## 2. Database File
Ensure `config/database.yml` has the username and password as defined in [docker/env](docker/env) file. The `config/database.yml` should already be gitignored.

The `COMMUNITY_NAME` value defined in the `.env` file defines the initial community name on your local DB.

the `COMMUNITY_ADMIN_USERNAME`, `COMMUNITY_ADMIN_PASSWORD` and `COMMUNITY_ADMIN_EMAIL` values in the `docker/env` file define the first user you can log in as. Please note that the password should be at least 6 characters long.

## 3. Build Containers

Next, you should build the images.

```bash
docker compose build
```

If you need to just rebuild one container, you can do that too.

```bash
docker compose build uwsgi
docker compose build db
docker compose build redis
```

NOTE: If you get an error like "Cannot connect to the Docker daemon at ...", you need to ensure you start docker. Depending on your system, this can be done with `sudo service docker start` (Ubuntu) or by opening the Docker Desktop application and waiting for it to start (Mac OS).

## 4. Start Containers

Then start your containers:

```bash
docker compose up # append -d (--detach) if you don't want to see output in the terminal
```

After about 20 seconds, check to make sure the server is running (and verify port 3000, note that you can change this mapping in the `.env` file)

```
qpixel_uwsgi_1  | => Booting Puma
qpixel_uwsgi_1  | => Rails 7.0.8.7 application starting in development 
qpixel_uwsgi_1  | => Run `bin/rails server --help` for more startup options
qpixel_uwsgi_1  | Puma starting in single mode...
qpixel_uwsgi_1  | * Puma version: 5.6.9 (ruby 3.1.2-p20) ("Birdie's Version")
qpixel_uwsgi_1  | *  Min threads: 5
qpixel_uwsgi_1  | *  Max threads: 5
qpixel_uwsgi_1  | *  Environment: development
qpixel_uwsgi_1  | *          PID: 99
qpixel_uwsgi_1  | * Listening on http://0.0.0.0:3000
qpixel_uwsgi_1  | Use Ctrl-C to stop
```

You should then be able to open your browser to [http://localhost:3000](http://localhost:3000)
and see the interface. 

![img/interface.png](../img/interface.png)

You can then click "Sign in" to login with what you defined for `$COMMUNITY_ADMIN_EMAIL` and `$COMMUNITY_ADMIN_PASSWORD`. Importantly, your password must be 6 characters or longer, otherwise the user won't be created.

### Custom build configs

If you are using a custom build config that doesn't automatically start Rails or our [config for local development](/docker/Dockerfile.dev), you will also have to manually start the server.

After the containers have started, connect to the uwsgi container (if you are using Docker Desktop, you can connect directly from the application):

```bash
docker exec -it qpixel-uwsgi-1 bash
```

And run the following command to start Rails (starting the server is intentionally disabled to allow for live debugging):

```bash
rails server -b 0.0.0.0
```

## 5. Login

Once you are logged in, you should see your icon in the top right:

![img/logged-in.png](../img/logged-in.png)

## 6. Configure Categories

Before you try to create a post we need to configure categories! 
Go to `http://localhost:3000/categories/`

![img/categories.png](../img/categories.png)

 Click "edit" for each category and scroll down to see the "Tag Set" field. This
 will be empty on first setup.

![img/tagset.png](../img/tagset.png)

You will need to select a tag set for each category! For example, the Meta category can be
associated with the "Meta" tag set, and the Q&A category can be associated with "Main"

![img/tagset-selected.png](../img/tagset-selected.png)

Make sure to click save for each one.

## 7. Create a Post

You should then be able to create a post! There are character requirements for the
body and title, and you are required at least one tag.

![img/create-post.png](../img/create-post.png)

And then click to "Save Post in Q&A"

![img/post.png](../img/post.png)

That's it!

## 8. Accessing emails
Running in this docker-compose setup, the system does not actually send emails. However, you can see the emails that would have been sent by going to [http://localhost:3000/letter_opener](http://localhost:3000/letter_opener).
This is especially useful to confirm other accounts that you make in the container.

## 9. Running commands in the docker container
Often, it may be useful to run some ruby/rails code directly, e.g. for debugging purposes. You can do so with the following command:

```bash
$ docker compose exec uwsgi rails runner "<ruby code here>"
Running via Spring preloader in process 111
```

It is also possible to open up a rails console to do more complicated things:

```bash
$ docker compose exec uwsgi rails c
```

Please keep in mind that for database related actions to work as expected, you first need to run the following in the rails console.

```ruby
RequestContext.community = Community.first
```

This correctly scopes all database actions to the first (and probably only) community in your system.

## 10. Running tests
To run the tests (except the system tests):

```bash
$ docker compose exec uwsgi rails test
```

To run the system tests:

```bash
$ docker compose exec uwsgi rails test:system
```

The system tests require a browser to be available (by default Firefox). Firefox is included in the uwsgi container if
you use `Dockerfile.dev`. If you use `Dockerfile` or `Dockerfile.arm` then you will need to add the relevant browser
yourself if you want to be able to run the system tests.

To run all of the tests (including the system tests):

```bash
$ docker compose exec uwsgi rails test:all
```

## 11. Stop Containers

When you are finished, don't forget to clean up.

```bash
docker compose stop
docker compose rm
```

## 12. Next steps

The current goal of this container is to provide a development environment for
working on QPixel. This deployment has not been tested with email notifications
enabled / set up, nor to deploy in production mode. If you require these 
modifications, please [open an issue](https://github.com/codidact/qpixel/issues).
