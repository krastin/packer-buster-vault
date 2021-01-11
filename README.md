# packer-consul-vagrant
A vagrant box based on debian buster with vault

# Prerequisites
## Install vagrant
Grab vagrant and learn how to install it from [here](https://www.vagrantup.com/docs/installation/).

## Install packer
Grab packer and learn how to install it from [here](https://www.packer.io/intro/getting-started/install.html).

## Install kitchen & prerequisites
Brace yourself for this one... Lifted from @kikitux with thanks.

### rbenv prerequisite

On MacOS:
```
brew install rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
rbenv init
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
source ~/.bash_profile
```

On Linux:
> Note:
> On Graphical environments, when you open a shell, sometimes `~/.bash_profile` doesn't get loaded
> You may need to `source ~/.bash_profile` manually or use `~/.bashrc`

```
apt update
apt install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-dev
wget -q https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer -O- | bash
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
rbenv init
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
source ~/.bash_profile
```

### bundle prerequisite

```
rbenv install 2.4.6 # this one works at the time of writing
rbenv local 2.4.6   # change to a newer version if needed
rbenv versions
gem install bundler
bundle install
```

# How to build

    make
    

# How to test

    make test


Or for more control over what happens:

```
bundle exec kitchen converge
bundle exec kitchen verify
bundle exec kitchen destroy
```

# How to publish

```
krastin@Krastins-MBP $ vagrant cloud auth whoami
In a moment we will ask for your username and password to HashiCorp's
Vagrant Cloud. After authenticating, we will store an access token locally on
disk. Your login details will be transmitted over a secure connection, and
are never stored on disk locally.

If you do not have an Vagrant Cloud account, sign up at
https://www.vagrantcloud.com

Vagrant Cloud username or email: krastin
Password (will be hidden):
Token description (Defaults to "Vagrant login from Krastins-MBP.lan"):
You are now logged in.
Currently logged in as krastin

krastin@Krastins-MBP $ vagrant cloud auth whoami

Currently logged in as krastin

krastin@Krastins-MBP $ export VERSION=1.4.0
krastin@Krastins-MBP $ vagrant cloud publish --box-version $VERSION --force --release krastin/buster-vault $VERSION virtualbox buster-vault-$VERSION.box
You are about to publish a box on Vagrant Cloud with the following options:
krastin/buster-vault:   (v1.4.0) for provider 'virtualbox'
Automatic Release:     true
==> cloud: Creating a box entry...
==> cloud: Creating a version entry...
==> cloud: Creating a provider entry...
==> cloud: Uploading provider with file /Users/krastin/workspace/packer-buster-vault/buster-vault-1.4.0.box
==> cloud: Releasing box...
Complete! Published krastin/buster-vault
tag:             krastin/buster-vault
username:        krastin
name:            buster-vault
private:         false
downloads:       0
created_at:      2020-06-26T14:14:50.626+02:00
updated_at:      2020-06-26T14:19:13.912+02:00
current_version: 1.4.0
providers:       virtualbox
old_versions:    ...
krastin@Krastins-MBP $
```

# Purpose

This repository attempts to store the minimum amount of code that is required to create a:
- Debian 10 Buster box
- with Vault
- using Packer
- for VirtualBox

# To Do


# Done
- [x] port build repository from ubuntu xenial