
# zoneedit

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with zoneedit](#setup)
    * [What zoneedit affects](#what-zoneedit-affects)
    * [Setup requirements](#setup-requirements)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

This is a puppet module used to install zoneedit and the accompanying files.

## Setup

### What zoneedit affects 

This module installas and manages the following componets
 * an uptodate copy of the icann zones repo
 * an uptodate copy of the icann zonedit repo and maintains links to the tool
 * bash-completion script for zoneedit
 * SSH private keys needed to keep the repositories up to date
 * SSH public key used by the zone repo pre-commit hook to ensure the zones repo is kept upto date with master

### Setup requierments
In order for the zones repo to stay up todate the pre-recive hook on the git server needs to be configuered to conect to this server and preform a git pull.  The git server should do this via SSH using the `git_pub_key` for authorisation

## Usage

simply include the zonedit class and set the `git_pub_key` and  `git_priv_key` values to the approprite value.  it is recomended to use eyaml for the prive key

```puppet
include zonedit
```
```yaml
zonedit::git_pub_key: 'AAAAPUBLICKEY'
zonedit::git_prive_key: 'ENC[PKCS7,MIIH/PRIVATEKEY]'
```

## Reference

### Classes

#### zonedit
* `git_pub_key` (String, Default: check module data): public key used to authorise the git server pre-recive hook
* `git_priv_key` (String, Default: check module data): the ssh\_private key used to clone git repos, this key should be configuered on the git server and be allowed to clone the two repos below
* `git_user` (String, Default: 'dns0ps'): the user on the zoneedit server used for git operations
* `zones_repo` (String, Default: 'git@git.dns.icann.org:/zonedit/zones.git'): the git repo containing the ICANN managed zone files
* `zonedit_repo` (String, Default: 'git@git.dns.icann.org:zonedit/zonedit.git'): the git repo used to manage the zonedit tool
