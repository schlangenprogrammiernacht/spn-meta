# SPN Meta Repository

This repository is a wrapper around the module repositories of the SPN system:
_gameserver_, _relayserver_ and _website_. It provides scripts to (hopefully)
simplify common tasks like preparing a new setup and running the programs.

## Prerequisites

For both development and production setups you need to have some dependencies
installed. You can use the following scripts to install them (or at least find
out what you need to install):

- openSUSE (Tumbleweed): `./install_deps_opensuse.sh`

## Development setup

The scripts intended for development purposes only are prefixed with `dev_`.
Here is an overview of the workflow:

To bring all submodules to the current development branches, run:

```sh
./dev_checkout_newest_version.sh
```

If this is your initial setup, you now need to adjust some configuration files:

- Configure database connection in `gameserver/src/Environment.h`
- Create `website/Programmierspiel/local_settings.py` from one of the templates
  in the same directory and configure database connection

When you’re done, you can build the programs. This will also apply the newest
migrations to the database.

```sh
./dev_build.sh
```

Now you can run the programs. If you want to run them manually, there is a
little helper script starting a `tmux` session with a window for each program
that’s already in the right working directory:

```sh
./dev_manual_tmux.sh
```

There’s also a script that runs all programs directly in a `tmux` session:

```sh
./dev_run.sh
```
