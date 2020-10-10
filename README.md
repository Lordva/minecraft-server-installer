# minecraft-server-installer

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/1b28d94d0b4446f4bd797988bfc2e0ac)](https://app.codacy.com/gh/Lordva/minecraft-server-installer?utm_source=github.com&utm_medium=referral&utm_content=Lordva/minecraft-server-installer&utm_campaign=Badge_Grade_Settings)
[![CodeFactor](https://www.codefactor.io/repository/github/lordva/minecraft-server-installer/badge)](https://www.codefactor.io/repository/github/lordva/minecraft-server-installer)

This python script automate the creation of minecraft paper servers.

### currently in developpement, Working as expected now !
status : 70%
## Roadmap

- [x] auto download of the latest version of paper
- [x] creating servers files and managing permissions
- [x] Bunggecord download/installation
- [x] Accept Eula automaticly
- [x] installing screen / managing server console w/ it
- [x] creating a service
- [x] java install (apt support only)
- [x] help page
- [ ] server update
- [ ] basic plugin install
- [ ] delete server functionality
- [ ] cleaning the code / adding comments

## Installation

Follow thoses steps to install and run the script

```
git clone https://github.com/lordva/minecraft-server-installer

cd minecraft-server-installer

sudo bash server-setup -c <number of servers> <server1> <server2> <server n> <server n+1>

```
Here is an exemple of the command above
```
sudo bash server-setup -c 3 lobby survival creative
```

Have fun w/ it
