# Adding a new programming language

**Please note:** _This documentation is not tested very well, some steps may be
missing. If you would like to add a programming language and something does not
work, do not hesistate to ask!_

The rough steps to add a new programming language are:

1. Register the new programming language in the system.
2. Create a bot framework. This is a wrapper around the players’ code that
   abstracts the communication with the gameserver and provides an easy-to-use
   API.
3. Create a Docker container.
4. Final integration.

The steps are detailed in the following sections.

## Registering the new Programming Language

The available programming languages are defined in the database, which is
populated from `website/core/fixtures/ProgrammingLanguage.json`. That file
contains one JSON object for each language. Here is the entry for C++, for
example:

```json
{
  "model": "core.ProgrammingLanguage",
  "pk": 1,
  "fields": {
    "slug": "cpp",
    "readable_name": "C++",
    "file_extension": "cpp",
    "editor_mode": "c_cpp"
  }
},
```

A short explanation of the keys:

- `model`: reference to the Django model to use. Hast to be `core.ProgrammingLanguage`.
- `pk`: the unique entry ID. Use the highest `pk` already in the file and add 1
  for your new entry. Do not change existing `pk`s.
- `slug`: a simplified version of the programming language name. This is used in URLs, filenames, etc.
- `readable_name`: the full name of the language. This is what will be shown on the website.
- `file_extension`: the file extension used for source code written in this language.
- `editor_mode`: mode of the ACE text editor associated with this language.
  This determines the syntax highlighting, for example. Take a look at the
  directory `website/ide/static/ide/ace/src/`: files called `mode-*.js` define
  editor modes.

Reload the database table after you updated `ProgrammingLanguage.json`:

```sh
$ cd website
$ source env/bin/activate
(env) $ ./manage.py loaddata core/fixtures/ProgrammingLanguage.json
```

## Creating a new Bot Framework

The bot framework is an abstraction layer between the player’s code and the raw
data from the gameserver. A good bot framework is:

- _readable_: the framework code should be understandable even by people who
  are just learning the language.
- _efficient_: the framework should have low overhead. Remember that the
  calculation time of the bot is limited by the gameserver, and any operations
  done by the framework are included in this time. Any time that the framework
  requires is not available to the player!
- _idiomatic_: the framework should be a good demonstration of the language’s
  possibilities. Make good use of the features your chosen language provides!
- _usable_: provide the tools the player needs. For example, if mathematical
  functions are only available with an additional library, install that library
  in the docker container and make a note somewhere in the documentation that
  it is installed.
- _documented_: the framework code, especially the API for the player, should
  be documented thoroughly. The documentation should be done such that it can
  be extracted from the code and can be provided to the player via the website
  (for example, the C++ framework uses Doxygen to accomplish that).

Of course, not all of these properties can be brought to perfection at the same
time. For example, a maximally efficient and idiomatic framework might not be
very readable, especially for a novice.

Please take a look at the C++ framework in
`gameserver/docker4bots/spn_cpp_base/spn_cpp_framework/`, which is the
reference framework, or other existing frameworks.

### The Interface to the Gameserver

The Bot uses two communication interfaces to the gameserver:

1. _Shared memory_ to exchange large data structures.
2. A _UNIX socket_ in `SOCK_SEQPACKET` mode for signalling.

Communication basically works as follows:

0. (before bot startup) The gameserver creates and listens on the socket. The
   bot is the client and connects to it.
1. The gameserver fills the shared memory with the relevant information.
2. The gameserver writes a command to the UNIX socket.
3. The bot processes the command, using and updating the data the shared
   memory.
4. When done, the bot writes a response to the UNIX socket.
5. Repeat from 1.

All exchanged data structures (also for signalling) are defined in
`gameserver/docker4bots/spn_cpp_base/spn_cpp_framework/src/ipc_format.h`. This
file is also used during compilation of the gameserver.

The shared memory is implemented as _POSIX shared memory_, i.e. a memory-mapped
file which resides on a `tmpfs`. `struct IpcSharedMemory` defines the data
structure of that file. Please note that the **alignment** of the structures is
**4 bytes**.

The most efficient method to provide the shared memory data to the player’s
code is to `mmap()` the file and then pass pointers/references to its contents
around. Avoid copying the data because that is really slow!

In some languages, it may not be possible to use `mmap()`. In that case, read
the relevant parts from the file and cache them in memory. When writing to the
persistent memory, do so with a selective write. Do not write the whole file
because that will take a lot of time.

The protocol on the UNIX socket is defined by `struct IpcRequest` and `struct
IpcResponse`. There are two requests: `INIT` which is sent once after the bot
has connected to the gameserver, and `STEP` which is sent every frame. Both
requests should be forwarded to the player’s code by calling a function there.
The bot can respond with either `OK` or `ERROR`; in the latter case it is
afterwards terminated by the gameserver. If the bot responds with `OK`, the
other fields, which are filled by/from the player’s code, determine the
behaviour of the bot in this frame.

## Creating a Docker Image

Now it is time to integrate your framework into the gameserver repository.

First, create the following directory structure, where `${SLUG}` is the
language’s shortname you defined earlier:
`gameserver/docker4bots/spn_${SLUG}_base/spn_${SLUG}_framework`. Especially the
part `spn_${SLUG}_base` is important, because that is what various scripts are
looking for.

### Bot Wrapper Script

Next, create a shell script named `bot_wrapper.sh` in `spn_${SLUG}_base`. This
script will serve as an entrypoint for your Docker image and will receive a
parameter that selects what the container should do. The parameters are
described in the next subsections.

If in doubt how this works, take a look at the C++ container under `spn_cpp_base`.

#### `compile`

The container shall generate an executable file from the player’s code.

The player’s code is available at `/spnbot/usercode.${EXT}`, where `${EXT}` is
the `file_extension` defined for this language in the database. The container
now has to prepare this code for execution, for example, by compiling it to a
binary. For scripting languages, this can also be a simple copy operation. The
executable file should be saved to `/spndata/bot`.

#### `run`

Here, the bot code shall be executed.

The binary generated by `compile` is again available as `/spndata/bot`.

#### `doc`

This is the target for documentation generation.

The documentation should be in a format that is usual for your chosen
programming language. If multiple options are available and HTML is one of
them, please use HTML.

Save the documentation files in `/doc`.

#### Other Arguments

If an argument is given that is not listed above, the script shall terminate with exit code 1.

### Dockerfile

Now create a [container build
script](https://docs.docker.com/engine/reference/builder/) named `Dockerfile`
in the `spn_${SLUG}_base` directory.

Here is an annotated example (with `${SLUG} = cpp`):

```dockerfile
# Select the base image.
FROM alpine

# Install necessary packages.
RUN apk add --no-cache g++ cmake strace make doxygen

# Create the user spnbot, which will execute everything that the player could
# influence. If in doubt, use this line verbatim in your Dockerfile.
RUN addgroup -S spnbot && adduser --uid 1337 --home /spnbot -S spnbot --shell /bin/sh -G spnbot

# Add the bot wrapper script.
ADD bot_wrapper.sh /

# Add the framework. Note that /spnbot is the $HOME of the spnbot user.
ADD spn_cpp_framework/ /spnbot/spn_cpp_framework

# pre-build framework, hand it over to the spnbot user and create the shared memory directory
# (all in one step to save layers)
RUN cd /spnbot/spn_cpp_framework && ./build.sh && chown -R spnbot /spnbot && mkdir /spnshm

# Define volumes that are mounted from the host. These must be available in any container.
VOLUME /spnshm
VOLUME /spndata

# Make spnbot the default user for this image.
USER spnbot

# Define the image’s entry point (default executable).
ENTRYPOINT ["/bot_wrapper.sh"]
```

A few additional notes:

- User code MUST NEVER come in touch with a process that is running as root in
  the container. That means: compiling and executing the bot code must be done
  in an unprivileged account (`spnbot` in the example above).
- Choose the base image wisely. Using an image tagged as _official_ in the
  [Docker Hub](https://hub.docker.com) is strongly recommended.
- Precompile the framework using some dummy user code while building the Docker
  image. Most build systems are intelligent enough to recognize that only
  the user code has changed when the container is started in `compile` mode
  later. This makes a *huge* difference when you have to compile thousands of
  bot revisions.
- Note that each command in the `Dockerfile` produces another filesystem layer
  for the image. Having many layers introduces overhead, so try to build
  the image in as few commands as possible. Especially try to execute
  multiple commands in a single `RUN`, as demonstrated in the example.

### Building the Container

You can build your image by using the following shell script:

```sh
$ cd gameserver/docker4bots
$ ./0_build_spn_base_container.sh ${SLUG}
```

The image will be tagged as `spn_${SLUG}_base:latest` when the build is
successful.

## Final integration

Now that you have a working Docker image, you can finally integrate the new
language in the website.

To do so, first generate the documentation for your new framework in the right
location:

```sh
$ cd gameserver/docker4bots
$ ./1_build_doc.sh ${SLUG} "../../website/docs/static/docs/${SLUG}"
```

This only needs to be done this way while developing the image. In normal
installations `1_build_doc.sh` is automatically called by
`01_build_all_docs_for_website.sh` for each language available.

Finally, edit `website/docs/templates/docs/docs.html` and add a paragraph for
the new language with a link to the documentation.

That’s all! You can now start all the programs as usual and your new language
should be usable.
