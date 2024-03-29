# SPN Meta Repository

This repository is a wrapper around the module repositories of the SPN system:
_gameserver_, _relayserver_ and _website_. It provides scripts to (hopefully)
simplify common tasks like preparing a new setup and running the programs.

## About Schlangenprogrammiernacht

Schlangenprogrammiernacht is a programming game written for the
[GPN19](https://entropia.de/GPN19). It is inspired by
[slither.io](https://slither.io), but here only bots written by the players
play against each other in a controlled environment.

The following screenshot gives an impression of the integrated IDE:

![The integrated IDE](doc/screenshots/ide.webp)

## Prerequisites

For both development and production setups you need to have some dependencies
installed. You can use the following scripts to install them (or at least find
out what you need to install):

Distribution            | Script
---                     | ---
openSUSE (Tumbleweed)   | `./install_deps_opensuse.sh`
Debian                  | `./install_deps_debian.sh`
Arch Linux              | `./install_deps_arch.sh`

## Server setup

This section describes the setup of a server system. It starts with setting up
a development system and in the end documents the remaining steps to convert
that to a “production” system.

A separate system user for running the SPN software is strongly recommended.
We will assume here that this user is called _spn_. You can create it as
follows:

```sh
$ useradd -m spn
```

### Prepare the repository

All major components of the system (gameserver, relayserver, website) are
located in Git submodules, which must first be initialized. After cloning this
repository, run:

```sh
$ git submodule update --init --recursive
```

You can use `./dev_checkout_newest_version.sh` to check out the latest commit
in each submodule instead of the currently referenced one.

### Configuring MariaDB

If this is your initial setup, you first need to set up `mariadb`. There's [a
pretty handy guide](https://wiki.archlinux.org/index.php/MariaDB#Installation)
in the Arch Linux Wiki, this should work for other platforms, too.

After the basic setup, create one user and database for SPN:

```sql
CREATE USER 'spn'@'localhost' IDENTIFIED BY 'MyVerySecurePassword!';
CREATE DATABASE spn;
GRANT ALL PRIVILEGES ON spn.* TO 'spn'@'localhost';
```

When you're done setting up one database and one user which has all privileges
in that db, you now need to adjust some configuration files:

- Configure database connection in `gameserver/src/Environment.h`
- Copy `website/Programmierspiel/local_settings.py.example` to
  `website/Programmierspiel/local_settings.py` and configure database
  connection.

Use the same database config for both files, even if the examples differ.

### Configuring Docker

On most systems, it is sufficient to add a user to the _docker_ group in order
to give access. Do so as follows:

```sh
$ gpasswd -a spn docker
```

Make sure you re-login into the _spn_ account before testing. If docker doesn't
work afterwards, look at the documentation for docker on your distribution.

Also don't forget to start the `docker` service.

```sh
$ systemctl start docker
```

Finally, build the base images for the bots:

```sh
$ cd gameserver/docker4bots
$ ./00_build_all_base_containers.sh
```

### (Not) Setting Up a Reverse Proxy

It is recommended (and in a production setup mandatory) to use a reverse
proxy in front of the website.

The reverse proxy separates the viewer websocket connection from the normal
website requests and redirects it to the _relayserver_. It also serves static
files in the production setup (see below).

#### Nginx on the Host

There is a template configuration in
[`helper_scripts/nginx.conf`](helper_scripts/nginx.conf). Copy it to your Nginx
configuration and adjust it to your needs.

#### Nginx in Docker

For a quick setup, you can also run Nginx in a Docker container. To do so, use
the script `helper_scripts/run_reverseproxy.sh`.

#### Running Without a Reverse Proxy

If you don't want to set up a reverse proxy, you can alternatively set up a
little hack in `website/visualization/Game.js` by inserting

```js
return 'ws://localhost:9009/websocket';
```

above

```js
return (window.location.protocol == "https:" ? "wss://" : "ws://") + window.location.host + "/websocket";
```

### Setting up shared memory

The shared memory used by the gameserver to communicate with the bots is
realized as memory-mapped files on a _tmpfs_. It is located at `/mnt/spn_shm`.

Unfortunately, the location is currently not easy to change, so please use this
directory if possible.

First, create the directory:

```sh
$ mkdir /mnt/spn_shm
```

For quick testing, there is a script that sets up the _tmpfs_:

```sh
$ gameserver/docker4bots/00_setup_shm_for_test.sh
```

If you want a more permanent setup, add this line to `/etc/fstab`:

```
none	/mnt/spn_shm	tmpfs	size=1G,noexec,uid=spn	0 0
```

### Building the Programs

There is a helper script that compiles the major components and sets up a
Python virtual environment for the Django-based website:

```sh
$ ./build.sh
```

Note: if you upgrade from an old version (before support for multiple
programming languages was implemented), the script might fail during the
database migration. In that case, import the programming language data and
retry the migration:

```sh
$ cd website
$ source env/bin/activate
(env) $ ./manage.py migrate # might still fail
(env) $ ./manage.py loaddata core/fixtures/ProgrammingLanguage.json
(env) $ ./manage.py migrate # should work now
(env) $ deactivate
```

If you upgrade from a previous version, the active bot binaries should be
recompiled, as the IPC format may have changed. To trigger that, open the mysql
client and run the following SQL query in your database:

```sh
$ mysql -u spn -p spn
```

```sql
UPDATE core_snakeversion SET compile_state="not_compiled" WHERE id IN (SELECT active_snake_id FROM core_userprofile);
```

This rebuilds all currently active binaries. To rebuild all snake versions ever
saved, remove the `WHERE` clause from the query. Beware: rebuilding everything
can take a very long time and users cannot run new versions until it the
rebuild is complete.

### Building the Documentation for the Bot Frameworks

The documentation for the bot frameworks is built using the Docker images that
are also used to build the bots. If you checked out the standard submodule
structure, you can use the following script to build the documentation and make
it available to users via the website:

```sh
$ cd gameserver/docker4bots/
$ ./01_build_all_docs_for_website.sh
```

### Running the Programs

Now you can run the programs. If you want to run them manually, there is a
little helper script starting a `tmux` session with a window for each program
that’s already in the right working directory:

```sh
$ ./dev_manual_tmux.sh
```

There’s also a script that runs all programs directly in a `tmux` session:

```sh
$ ./run.sh
```

If you use the template [`nginx.conf`](helper_scripts/nginx.conf) as-is, you
should now be able to access the SPN server on http://localhost:3000 .

**NEVER** open this server to the Internet. Django’s debug mode will allow
everybody to gain full access to the user account Django is running on. To get
a secure setup, read the next section.

### Setting up a Production System

This section modifies the setup described above such that it can be provided to
a wider audience.

#### Django configuration

Django’s debug mode must be disabled and static files should be served by the
reverse proxy. To accomplish this, adjust
`website/Programmierspiel/local_settings.py` as follows (add variables that
don’t exist yet):

```python
DEBUG = False
ALLOWED_HOSTS = ['127.0.0.1', 'your.domain.here']
SECRET_KEY = 'make_sure_you_do_not_use_the_one_in_the_template!'
STATIC_ROOT = '/var/www/spn/staticfiles'
```

#### Static Files

Add the following to your Nginx configuration:

```
location /static/ {
	alias /var/www/spn/staticfiles/;
}
```

Then, store the static files in the configured directory:

```sh
$ cd website
$ source env/bin/activate
$ ./manage.py collectstatic
```

#### Final remarks

Restart Nginx and all SPN programs.

You now have a safe SPN production server that hopefully succeeds in killing
some productivity 😈

## External Contributions

This is a collection of SPN-related things developed by others.

* [Ansible role for installing SPN on Debian 10](https://git.bingo-ev.de/geierb/spn-ansible) by citronalco

## Adding a new programming language

This is described in a [separate document](HOWTO_add_programming_languages.md).
