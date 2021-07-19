# apostol-nhbot

**NiceHash Bot (`nhbot`)** - Bot for automatic order management.

Implementation in the form of REST API Web Service, in C++.

Built on base [Apostol](https://github.com/ufocomp/apostol).

The software stack consists of a compilation of source code, libraries and scripts.

Overview
-
So far, this is just a blank.

Task number #1: Teach the bot to reduce the cost of orders.

Build and installation
-
Build required:

1. Compiler C++;
1. [CMake](https://cmake.org);
1. Library [libdelphi](https://github.com/ufocomp/libdelphi/) (Delphi classes for C++);
1. Library [libpq-dev](https://www.postgresql.org/download/) (libraries and headers for C language frontend development);
1. Library [postgresql-server-dev-10](https://www.postgresql.org/download/) (libraries and headers for C language backend development).

###### **ATTENTION**: You do not need to install [libdelphi](https://github.com/ufocomp/libdelphi/), just download and put it in the `src/lib` directory of the project.

To install the C ++ compiler and necessary libraries in Ubuntu, run:
~~~
sudo apt-get install build-essential libssl-dev libcurl4-openssl-dev make cmake gcc g++
~~~

To install PostgreSQL, use the instructions for [this](https://www.postgresql.org/download/) link.

###### A detailed description of the installation of C ++, CMake, IDE, and other components necessary for building the project is not included in this guide. 

To install with Git you need:
~~~
git clone https://github.com/ufocomp/apostol-nhbot.git
~~~

###### Build:
~~~
cd apostol-nhbot
./configure
~~~

###### Compilation and installation:
~~~
cd cmake-build-release
make
sudo make install
~~~

By default **`nhbot`** will be set to:
~~~
/usr/sbin
~~~

The configuration file and the necessary files for operation, depending on the installation option, will be located in:
~~~
/etc/apostol-nhbot
or
~/apostol-nhbot
~~~

Run
-
###### If **`INSTALL_AS_ROOT`** set to `ON`.

**`nhbot`** - it is a Linux system service (daemon). 

To manage **`nhbot`** use standard service management commands.

To start, run:
~~~
sudo service nhbot start
~~~

To check the status, run:
~~~
sudo service nhbot status
~~~
