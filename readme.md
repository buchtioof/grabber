![grabber logo](./static/billboard.png)

# Grabber - Fetch all your PC

## About
Grabber is an administration interface that allows you to manage a group of computers at a glance.\
*it's a school project, learn more about the project [in the docs notes (in french)](https://buchtioof.github.io/notes/projects/2025-12-05/)*

## Usage

### For pre-release versions

Firstly, git clone this repo:\
`git clone https://github.com/buchtioof/grabber.git`

Then, inside your cloned directory, run the bash script:\
`./grabber.sh`

In order to use [Alfred](https://github.com/buchtioof/alfred) and fetch other computers data, you will need to add the host ip address in settings.json
```json
{
  "ip_address": "", # if no address detected, grabber use localhost, important to change for Alfred
  "port": "8000", # change if you need a custom port
  "session_token": "" # no need to touch it as it update each times you'll launch grabber
}
```

## Versions

### Pre-release phase

- v0.1 : Grabber base, write fetch data in summary.txt needs upgrades
- v0.2 : Use admin to fetch more data like cpu info
- v0.3 : Minimal uvicorn usage, shows data fetch for one pc saved in json data locally
- v0.4 : Save fetch data in a sql database and can save multiple pc in a pretty interface
- v0.5 : Switch to Django, use API model, security update by using session tokens to verify communications, use [Alfred](https://github.com/buchtioof/alfred) to fetch data via SSH
- v0.6 : Admin panel refine, login page rework, local session verification that locks Alfred (SSH injection), switch CSS to Tailwind local, employees management and links between them and PCs
- v0.7 : QOL update, settings added, employees modal reworked, added middleware (manage timezone in Django)
- v0.8 (actual) : Use SSH keys to reconnect safely, Languages update in beta (English and French available)
- v0.9 (next) : Clean and verified code
- v1 : Deployment with Docker, all working fine

## Dependencies

To run Grabber properly on your device, you will need these 3 dependencies available:
- [jq](https://github.com/jqlang/jq)
- [Python3](https://www.python.org/)
- [Sqlite3](https://sqlite.org/index.html)

Grabber will install automatically these 2 dependencies in python virtual environment:
- [Paramiko](https://www.paramiko.org/)
- [Django](https://www.djangoproject.com/)

These ones is already available in Grabber:
- [Alfred](https://github.com/buchtioof/alfred)
- [Tailwind](https://tailwindcss.com/)
- [Phosphor Icons](https://phosphoricons.com/)

## Project rules

### Versioning in this project

Every updates starts with the letter v and uses three numbers separated by points (example: v0.8.1 or v1.0.5)

- Each bug fixes and light cleaning code is coded by the third number of the version code (example: vx.x.N / N as the update number)
- A feature added is coded by the second number of the version code (example: vx.N / N as the update number)
- When the project is at a stable point and has all the features planned, it is coded by the first number of the version code (example: vN / N as the update number)

### Git usage

Branches use the versioning rules: (*N stands for the version number*)

- To work on a feature update, create a branch called feature-vx.N
- For a bug fix, create a branch called bugfix-vx.x.N

Before merging, be sure the code is verified and clean as possible, use comments

# Credits
To the big work of all the dependencies used\
To [kawaiiLogos](https://github.com/SAWARATSUKI/KawaiiLogos) for the logo inspiration
