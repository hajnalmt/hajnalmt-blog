---
title: The intricacies of a laravel project setup with sail under WSL2
author:
  name: Mate Hajnal
  link: https://gitlab.com/hajnalmt
categories: [Laravel, Sail, WSL2]
tags: [laravel, sail, wsl2, dnsproblem, dns]
toc: false
pin: true
---

I needed to create a laravel blog motor for one of my interviews in the past 2 weeks, and even to just get started I bumped into some problems.
To be a little bit more specific, the problem was that the WSL2 DNS settings are a little bit vague, and I am quite surprised that I didn't find more complaint about it. Basically 2-3 issues and posts which I was able to find.
So if you managed to get here due to the same errors I got, this post will help.

### The command which shall work

To get started with a laravel project even the new Laravel 9 documentation says that use sail under WSL2 to get started, and this is big a relief for me, that even the laravel community jumped into the microservice architecture-base development. No more XAMPP and php version management, thank god times are changing.

So the official [Laravel 9 docs](https://laravel.com/docs/9.x/installation#getting-started-on-windows) suggests to install WSL2 and Docker Desktop. To be fair I had a WSL2 Ubuntu 20.04 LTS with a docker-ce and docker-cli installed already and due to the last years [licensing misery](https://www.docker.com/blog/updating-product-subscriptions/) of the Docker Desktop I try to stay away from it.

This means that according to the docs, one curl command and I shall be ready to go:

```bash
curl -s "https://laravel.build/little-laravel-blog/?with=pgsql,selenium" | bash
```

With the project name little-laravel-blog, I went with the postgres and selenium based service setup, because for a blog motor I won't need anything more.
The CLI output was the following:

```bash
 _                               _
| |                             | |
| |     __ _ _ __ __ ___   _____| |
| |    / _` | '__/ _` \ \ / / _ \ |
| |___| (_| | | | (_| |\ V /  __/ |
|______\__,_|_|  \__,_| \_/ \___|_|

Warning: TTY mode requires /dev/tty to be read/writable.
    Creating a "laravel/laravel" project at "./example-app"
    https://repo.packagist.org could not be fully loaded (curl error 6 while downloading https://repo.packagist.org/packages.json: Could not resolve host: repo.packagist.org), package information was loaded from the local cache and may be out of date
    The following exception probably indicates you have misconfigured DNS resolver(s)


  [Composer\Downloader\TransportException]
      curl error 6 while downloading https://repo.packagist.org/p2/laravel/laravel.json: Could not resolve host: repo.packagist.org


    create-project [-s|--stability STABILITY] [--prefer-source] [--prefer-dist] [--prefer-install PREFER-INSTALL] [--repository REPOSITORY] [--repository-url REPOSITORY-URL] [--add-repository] [--dev] [--no-dev] [--no-custom-installers] [--no-scripts] [--no-progress] [--no-secure-http] [--keep-vcs] [--remove-vcs] [--no-install] [--ignore-platform-req IGNORE-PLATFORM-REQ] [--ignore-platform-reqs] [--ask] [--] [<package>] [<directory>] [<version>]

bash: line 16: cd: example-app: No such file or directory
```

No directory created so what happened?

### The DNS resolver error

The output suggests that the problem is probably with my dns setup.
When I checked, what are the commands I try to run exactly, and entered the [curled url](https://laravel.build/little-laravel-blog/?with=pgsql,selenium) in a browser, it came out that it just runs <code>{% raw %}laravelsail/php81-composer:latest{% endraw %}</code> container with an artisan command.

So I thought that maybe I will try to run the command myself and reproduce the issue, and I managed to do it.

```bash
docker run -dti -v "$(pwd)":/opt --name sail-container -w /opt laravelsail/php81-composer:latest

root@7650f724374c:/opt# laravel new little-laravel-blog

 _                               _
| |                             | |
| |     __ _ _ __ __ ___   _____| |
| |    / _` | '__/ _` \ \ / / _ \ |
| |___| (_| | | | (_| |\ V /  __/ |
|______\__,_|_|  \__,_| \_/ \___|_|

Creating a "laravel/laravel" project at "./little-laravel-blog"
https://repo.packagist.org could not be fully loaded (curl error 6 while downloading https://repo.packagist.org/packages.json: Could not resolve host: repo.packagist.org), package information was loaded from the local cache and may be out of date
The following exception probably indicates you have misconfigured DNS resolver(s)


  [Composer\Downloader\TransportException]
  curl error 6 while downloading https://repo.packagist.org/p2/laravel/laravel.json: Could not resolve host: repo.pac
  kagist.org


create-project [-s|--stability STABILITY] [--prefer-source] [--prefer-dist] [--prefer-install PREFER-INSTALL] [--repository REPOSITORY] [--repository-url REPOSITORY-URL] [--add-repository] [--dev] [--no-dev] [--no-custom-installers] [--no-scripts] [--no-progress] [--no-secure-http] [--keep-vcs] [--remove-vcs] [--no-install] [--ignore-platform-req IGNORE-PLATFORM-REQ] [--ignore-platform-reqs] [--ask] [--] [<package>] [<directory>] [<version>]
```

So in the meantime I checked the dns settings of the container:

```bash
root@7650f724374c:/opt# cat /etc/resolv.conf
# This file was automatically generated by WSL. To stop automatic generation of this file, add the following entry to /etc/wsl.conf:
# [network]
# generateResolvConf = false
nameserver 172.17.160.1
root@7650f724374c:/opt# exit
```

Which does not seemed right, this IP address seemed weird, and it came out that the container is initialized with the WSL's dns servers, and indeed, this was the dns configuration of my Ubuntu 20.04, so how to change it?
After some digging into the [docker networking documentation](https://docs.docker.com/config/containers/container-networking/) I started the container again with the 8.8.8.8 dns flag:

```bash
docker run -dti -v "$(pwd)":/opt --name sail-container --dns 8.8.8.8 -w /opt laravelsail/php81-composer:latest
```

And voilá, everything went fine now.

```bash
Sun Mar 20 12:53:58 0 hajnalmt@DESKTOP-N55OACK:~/own
docker exec  -it sail-container /bin/bash
root@6c5393281f67:/opt# cat /etc/resolv.conf
nameserver 8.8.8.8
root@6c5393281f67:/opt# ls
hajnalmt-blog  hajnalmt-hosting  o1g.ci
root@6c5393281f67:/opt# cat /etc/resolv.conf ^C
root@6c5393281f67:/opt# laravel new little-laravel-blog

 _                               _
| |                             | |
| |     __ _ _ __ __ ___   _____| |
| |    / _` | '__/ _` \ \ / / _ \ |
| |___| (_| | | | (_| |\ V /  __/ |
|______\__,_|_|  \__,_| \_/ \___|_|

Creating a "laravel/laravel" project at "./little-laravel-blog"
Info from https://repo.packagist.org: #StandWithUkraine
Installing laravel/laravel (v9.1.2)
  - Downloading laravel/laravel (v9.1.2)
  - Installing laravel/laravel (v9.1.2): Extracting archive
Created project in /opt/little-laravel-blog
> @php -r "file_exists('.env') || copy('.env.example', '.env');"
Loading composer repositories with package information
Info from https://repo.packagist.org: #StandWithUkraine
Updating dependencies
Lock file operations: 108 installs, 0 updates, 0 removals
  - Locking brick/math (0.9.3)
  - Locking dflydev/dot-access-data (v3.0.1)
  - Locking doctrine/inflector (2.0.4)
  - Locking doctrine/instantiator (1.4.1)
  - Locking doctrine/lexer (1.2.3)
  - Locking dragonmantank/cron-expression (v3.3.1)
...
Use the `composer fund` command to find out more!
> @php artisan vendor:publish --tag=laravel-assets --ansi --force
No publishable resources for tag [laravel-assets].
Publishing complete.
> @php artisan key:generate --ansi
Application key set successfully.

Application ready! Build something amazing.
```

### Editing the compose file too

Despite solving this issue, the problem still came up when I tried the <code>{% raw %}sail up{% endraw %}</code> command.
At first I tried to edit my wsl2 dns configuration (which is the main reason this whole laravel setup just doesn't work at a glance).
After several try, I just gave up. I have tried every method, the [internet suggested](https://superuser.com/questions/1533291/how-do-i-change-the-dns-settings-for-wsl2). I even crashed wsl with one of my attempt, but the main problem that the dns configuration gets generated on every new restart, so either your configuration will be lost after restarting the terminal, or there is a possibility, that you will mess up your dns configuration, which is not fun.

The permanent solution is just to edit your docker-compose.yml file to use the google dns.

```yaml
# For more information: https://laravel.com/docs/sail
version: "3"
services:
  laravel.test:
    build:
      context: ./vendor/laravel/sail/runtimes/8.1
      dockerfile: Dockerfile
      args:
        WWWGROUP: "${WWWGROUP}"
    image: sail-8.1/app
    extra_hosts:
      - "host.docker.internal:host-gateway"
    dns: 8.8.8.8 # I ADDED THIS LINE
    ports:
      - "${APP_PORT:-80}:80"
    environment:
      WWWUSER: "${WWWUSER}"
      LARAVEL_SAIL: 1
      XDEBUG_MODE: "${SAIL_XDEBUG_MODE:-off}"
      XDEBUG_CONFIG: "${SAIL_XDEBUG_CONFIG:-client_host=host.docker.internal}"
    volumes:
      - ".:/var/www/html"
  # ...
```

I basically added a dns entry to the laravel test service.

I hope the post helped you, if you bumped into this same issue.
