[![Puppet
Forge](http://img.shields.io/puppetforge/v/puppetlabs/apk.svg)](https://forge.puppetlabs.com/puppetlabs/apk)
[![Build
Status](https://travis-ci.org/puppetlabs/puppetlabs-apk.svg?branch=master)](https://travis-ci.org/puppetlabs/puppetlabs-apk)

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with apk](#setup)
4. [Usage - Configuration options and additional functionality](#setup)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

APK is the built-in package manager for [Alpine Linux](http://www.alpinelinux.org/), a tiny Linux distribution built with size, security and correctness in mind.

## Module Description

The module allows for managing system packages with Puppet on Alpine Linux, using the APK package manager. Once installed the module works like all other package providers.

## Setup

Installation is a simple matter of:

```bash
puppet module install puppetlabs-apk
```

## Usage

Using the module can be done by explicitly setting the provider, like so:

```puppet
package { 'ruby':
  ensure   => installed,
  provider => apk,
}
```

Note that the provider will only work in cases where the `operatingsystem` fact is set to `Alpine`.

Because the new provider is set to be the default package provider for Alpine Linux you actually don't need to specify the provider at all though:

```puppet
package { 'ruby':
  ensure => installed,
}
```

It's also possible to pass additional arguments to the underlying `apk`
binary when packages are installed, using the `install_options`
parameter. For instance:

```puppet
package { 'shadow':
  ensure          => installed,
  install_options => ['--update-cache', '--repository http://dl-3.alpinelinux.org/alpine/edge/testing/', '--allow-untrusted'],
}
```

You can also ensure packages are not present with `ensure => absent` and the provider enables puppet resource support on Alpine, so running the following will list all installed packages wit their versions.

```bash
puppet resource package
```

### A note on Puppet on Alpine

A native `puppet-agent` package is not currently available for Alpine, but Puppet can be installed using the system Ruby and the gems package manager. Ruby also requires some additional system packages to function correctly. The following should get you started if you're looking to use Puppet on Alpine.

```bash
sudo -s
# required for the shadow package, which is needed for the User resource
echo http://dl-4.alpinelinux.org/alpine/edge/testing/ >> /etc/apk/repositories
apk update
apk add ruby shadow less
gem install puppet --no-ri --no-rdoc
```

Note as well that the blockdevice facts on Alpine require root permissions, so unless you delete those facts you will need to run `facter` and `puppet` with sudo or as root. If you'd rather not do so you can delete the offending facts with the following:

```bash
sudo rm /usr/lib/ruby/gems/2.2.0/gems/facter-2.4.6/lib/facter/blockdevices.rb
```

### Todo

The module does not update the package cache, but it would be nice to provide a resource to do so. The module also does not yet provide support for managing APK repositories but that would also be a useful addition. These may be added later, but pull requests would also be galdly accepted.

## Limitations

As noted the module does not work on operating systems other than Alpine, but in those cases you probably have a different package manager with a suitable provider. The module is not supported with Puppet Enterprise as Alpine Linux is not a supported platform at this time, and a suitable `puppet-agent` package is not available.
