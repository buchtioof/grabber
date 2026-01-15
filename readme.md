![grabber logo](./logo.png)

# Grabber - Fetch all your PC

## About
Grabber is a bash program that fetch some informations of the computer like memory, storage or cpu for exemple.

## Dependencies
- inxi
- dmidecode

## Versions
- v0 : grabber base, works minimal, ask permission, needs upgrades and rework

# Credits
Logo inspired by [kawaiiLogos](https://github.com/SAWARATSUKI/KawaiiLogos) project

python3 -m venv gbvenv
  182  source gbvenv/bin/activate
  183  pip install --upgrade pip
  184  python -m pip install fastapi
  185  pip freeze >> requirements.txt
  186  echo ¨gbvenv¨ >> .gitignore
