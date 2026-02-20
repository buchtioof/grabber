![grabber logo](./assets/logo.png)

# Grabber - Fetch all your PC

## About
Grabber is an administration interface that allows you to manage a group of computers at a glance.
*it's a school project*

## Usage

### for v0.5

firstly, git clone this repo:\
`git clone https://github.com/buchtioof/grabber.git`

then, inside your cloned directory, run the bash script:\
`./grabber.sh`

in order to use [Alfred](https://github.com/buchtioof/alfred) and fetch other computers data, you will need to add the host ip address in settings.json
```json
{
  "ip_address": "", # if no address detected, grabber use localhost, important to change for Alfred
  "port": "8000", # change if you need a custom port
  "session_token": "" # no need to touch it as it update each times you'll launch grabber
}
```

## Versions
- v0.1 : grabber base, write fetch data in summary.txt needs upgrades
- v0.2 : use admin to fetch more data like cpu info...
- v0.3 : minimal uvicorn usage, shows data fetch for one pc saved in json data locally
- v0.4 : save fetch data in a sql database and can save multiple pc in a pretty interface
- v0.5 (actual) : switch to Django, use API model, security update by using session tokens to verify communications, use [Alfred](https://github.com/buchtioof/alfred) to fetch data via SSH
- v0.6 (wip) : adding admin tools (add/rm employees...), rework admin panel (not made by me atm)

## Dependencies
- inxi
- python3
- sqlite3
- paramiko
- django
- jq
- alfred (mine yea boi)

# Credits
Logo inspired by [kawaiiLogos](https://github.com/SAWARATSUKI/KawaiiLogos) project
