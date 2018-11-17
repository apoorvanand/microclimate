## Local microclimate deployment

### Prerequisites
* [Docker](https://www.docker.com/get-docker) **v17.06 minimum**
* Linux only: follow post-installation steps to
  * [Run docker as a non-root user](https://docs.docker.com/engine/installation/linux/linux-postinstall/)
  * [Update docker-compose](https://docs.docker.com/compose/install/)
* Windows
  * Windows 10 or Windows Server 2016
  * [Docker for Windows](https://www.docker.com/docker-windows)
  * We strongly recommend that you do not run using Experimental Features enabled (which is enabled by default in Docker for Windows). To turn it off, go to Docker->Settings->Daemon and de-select Experimental Features.

#### Linux/MacOS
1. Install the Microclimate CLI. This will install the mcdev command as a link in your HOME directory:
```
cd cli
./install.sh
cd ..
```
2. Start Microclimate. This will download docker images and open Microclimate in your default browser:
```
~/mcdev start -o
```

#### Windows
1. Install the Microclimate CLI. This will add the mcdev command to your PATH:
```
cli\install.ps1
```
2. Start Microclimate. This will download docker images and open Microclimate in your default browser:
```
mcdev start
```

### Microclimate CLI
```
Usage:  mcdev COMMAND

Commands:
  start             Pull Microclimate docker images and start Microclimate
  open              Open Microclimate in your browser
  stop              Stop Microclimate docker containers
  update            Update Microclimate docker images
  delete            Delete Microclimate docker images
```
