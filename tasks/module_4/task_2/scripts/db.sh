#!/usr/bin/env bash

is_latin_letters() {
  if [[ $1 =~ ^[a-zA-Z]+$ ]]; then
    return 0
  else
    return 1
  fi
}

if [ ! -f ../data/users.db ]; then
  read -p "There is no such file. Would you like to create ? (y/n): " response
  if [ $response = "y" ] || [ $response = "Y" ]; then
    touch ../data/users.db
    echo "File created."
  else
    exit 0
  fi
fi

if [[ $1 = 'add' ]]; then
  read -p "Enter a username (Latin letters only): " username
  if ! is_latin_letters $username; then
    echo "Invalid username. Please use only Latin letters."
    exit 0
  fi

  read -p "Enter a role (Latin letters only): " role
  if ! is_latin_letters $role; then
    echo "Invalid role. Please use only Latin letters."
    exit 0
  fi

  echo "${username}, ${role}" >>../data/users.db
  echo "New entity added to ../data/users.db: ${username}, ${role}"
fi

if [[ $1 = 'help' || $1 = '' ]]; then
  echo "$1 is intended for process operations with users database and supports next commands:"
  echo -e "\tadd -> add new entity to database;"
  echo -e "\thelp -> provide list of all available commands;"
  echo -e "\tbackup -> create a copy of current database;"
  echo -e "\trestore -> replaces database with its last created backup;"
  echo -e "\tfind -> found all entries in database by username;"
  echo -e "\tlist -> prints content of database and accepts optional 'inverse' param to print results in opposite order."
  exit 0
fi

if [[ $1 = 'backup' ]]; then
  cp ../data/users.db ../data/$(date +"%m-%d-%Y")-users.db.backup
  echo "Data from users.db was copied to $(date +"%m-%d-%Y")-users.db.backup"
  exit 0
fi

if [[ $1 = 'restore' ]]; then
  if [ ! -f ../data/*.backup ]; then
    echo "No backup file found"
    exit 0
  fi

  cp ../data/*.backup ../data/users.db
  echo "Data from *.backup was restored to users.db"
  exit 0
fi

if [[ $1 = 'find' ]]; then
  read -p "Enter a username for search (Latin letters only): " username
  if ! is_latin_letters $username; then
    echo "Invalid username. Please use only Latin letters."
    exit 0
  fi

  search_result=$(grep -i $username ../data/users.db | awk '{print $1}')

  if [[ -n $search_result ]]; then
    echo "Found entries in ../data/users.db:"
    echo -e "$(grep -i $username ../data/users.db)\n"
    exit 0
  else
    echo "User not found"
    exit 0
  fi
fi

if [[ $1 = 'list' ]]; then
  fileContent=$(awk '{ print NR". " $0 }' <../data/users.db)
  if [ -z $2 ]; then
    echo "$fileContent"
  else
    echo "$fileContent" | tac
  fi
fi
