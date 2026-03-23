![grabber logo](./static/billboard.png)

# Grabber - Fetch all your PC

## About
Grabber is an administration interface that allows you to manage a group of computers at a glance.\
*it's a school project, learn more about the project [in the docs notes (in french)](https://buchtioof.github.io/notes/projects/2025-12-05/)*

## Usage

### Docker deployment

Firstly, git clone this repo:\
`git clone https://github.com/buchtioof/grabber.git`

In order to use properly your admin panel, create an .env file with these variables:\
```text
# Fill the blank spaces with your host IP, a username, an email and a password for admin user in order to use Grabber Admin.
# DO NOT USE ""

# SERVER SETTINGS
HOST=
PORT=8000

# ADMIN SETTINGS
DJANGO_SUPERUSER_USERNAME=
DJANGO_SUPERUSER_EMAIL=
DJANGO_SUPERUSER_PASSWORD=
```

Then, build the container with docker-compose:\
`docker-compose up -d --build`

Finally, access to your Grabber panel via the IP you've given in your .env file!

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

## Changelogs

### Pre-release phase

- v0.1 : Grabber base, write fetch data in summary.txt needs upgrades
- v0.2 : Use admin to fetch more data like cpu info
- v0.3 : Minimal uvicorn usage, shows data fetch for one pc saved in json data locally
- v0.4 : Save fetch data in a sql database and can save multiple pc in a pretty interface
- v0.5 : Switch to Django, use API model, security update by using session tokens to verify communications, use [Alfred](https://github.com/buchtioof/alfred) to fetch data via SSH
- v0.6 : Admin panel refine, login page rework, local session verification that locks Alfred (SSH injection), switch CSS to Tailwind local, employees management and links between them and PCs
- v0.7 : QOL update, settings added, employees modal reworked, added middleware (manage timezone in Django)
- v0.8 : Use SSH keys to reconnect safely, Languages update in beta (English and French available)
- v0.9 : Use Gunicorn+Whitenoise for production, bug fixes, clean and verified code

### Production releases

- v1 (actual) : Deployment with Docker, all working fine

## Contributing

In order to develop new features or work on the design, launch Grabber by using the docker-compose dedicated for development:
```
# enable HOT RELOADING and DEBUG in Django
docker-compose -f docker-compose.dev.yml up
```

## Dependencies

To run Grabber properly on your device, you will need these 3 dependencies available:
- [jq](https://github.com/jqlang/jq)
- [Python3](https://www.python.org/)
- [Sqlite3](https://sqlite.org/index.html)

Grabber will install automatically these 4 dependencies in python virtual environment:
- [Paramiko](https://www.paramiko.org/)
- [Django](https://www.djangoproject.com/)
- [Gunicorn](https://gunicorn.org/)
- [Whitenoise](https://github.com/evansd/whitenoise)

These 3 are already available in Grabber:
- [Alfred](https://github.com/buchtioof/alfred)
- [Tailwind](https://tailwindcss.com/)
- [Phosphor Icons](https://phosphoricons.com/)

# Credits
To the big work of all the dependencies used\
To [kawaiiLogos](https://github.com/SAWARATSUKI/KawaiiLogos) for the logo inspiration
