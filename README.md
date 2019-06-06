# SPN Meta Repository

This repository is a wrapper around the module repositories of the SPN system:
_gameserver_, _relayserver_ and _website_. It provides scripts to (hopefully)
simplify common tasks like preparing a new setup and running the programs.

## Prerequisites

For both development and production setups you need to have some dependencies
installed. You can use the following scripts to install them (or at least find
out what you need to install):

Distribution            | Script
---                     | ---
openSUSE (Tumbleweed)   | `./install_deps_opensuse.sh`
Debian                  | `./install_deps_debian.sh`
Arch Linux              | `./install_deps_arch.sh`

> Note: The Debian Dep-Script may be incomplete.

## Development setup

The scripts intended for development purposes only are prefixed with `dev_`.
Here is an overview of the workflow:

To update all submodules to the current development state, run:

```sh
$ git submodule update --init --recursive
```

If this is your initial setup, you first need to set up `mariadb`. There's [a pretty handy guide](https://wiki.archlinux.org/index.php/MariaDB#Installation) in the Arch Linux Wiki, this should work for other platforms, too. When you're done setting up one database and one user which has all privileges in that db, you now need to adjust some configuration files:

- Configure database connection in `gameserver/src/Environment.h`
- Create `website/Programmierspiel/local_settings.py` from one of the templates in the same directory and configure database connection

You'll want to use the database and the credentials you set up in `mariadb`. If you've never set up docker before, add yourself to the `docker` group. Also don't forget to start the `docker` service.

```\sh
I'm not sure what the inter-dist version of that cmd was, pls insert here
```

Then you'll need to pull the `alpine` docker image (this is the image the bots will run on, in seperate containers):

```sh
$ docker pull alpine:latest
```

When you’re done, you can build the programs. This will also apply the newest
migrations to the database.

```sh
$ ./dev_build.sh
```

Now you can run the programs. If you want to run them manually, there is a
little helper script starting a `tmux` session with a window for each program
that’s already in the right working directory:

```sh
$ ./dev_manual_tmux.sh
```

There’s also a script that runs all programs directly in a `tmux` session:

```sh
$ ./dev_run.sh
```

If you don't want to set up a reverse proxy (you could use `nginx` or, hypothetically, `traefik` for that) you can alternatively set up a little hack in `website/visualization/Game.js` by inserting

```js
return 'ws://localhost:9009/websocket';
```

above

```js
return (window.location.protocol == "https:" ? "wss://" : "ws://") + window.location.host + "/websocket";
```

If you just want a quick and dirty testing setup, uncomment

```sh
sudo gameserver/docker4bots/00_setup_shm_for_test.sh
```

in `helper_scripts/run_dev_website.sh`.
