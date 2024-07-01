<div>
  <h1 align="center">create-users</h1>
  <h3 align="center">Because you are too lazy to do it manually</h5>
</div>

A shell script which create users, assign them to groups, and set their passwords automatically.

## What it does
- Reads the users and groups supplied in the .txt file
- Creates the users and groups from read data
- Assigns randomly generated password to each user. Passwords are saved in `/var/secure/user_passwords.csv`
- Adds users to appropriate groups
- Creates a `$HOME` directory for each user with appropriate permission
- Logs all script actions in `/var/log/user_management.log`

## Running
Script must be run as root(#).
```bash
$ git clone https://github.com/xtasysensei/create-users-bash.git
$ cd create-users-bash 

# run as root 
$ bash create_user.sh <name-of-text-file>
```

## Dependencies
- your favorite POSIX-compliant shell (only tested on [bash](https://repology.org/project/bash/packages))

## OS
Works in any GNU/Linux environment

## Caution
This script will modify current configuration. Only use after thorough verification. The Author is not liable for any damages caused by this script. 