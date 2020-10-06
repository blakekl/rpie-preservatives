# rpie-preservatives

## Table of Contents

- [rpie-preservatives](#rpie-preservatives)
  - [Table of Contents](#table-of-contents)
  - [About](#about)
  - [How it works](#how-it-works)
    - [excluded files](#excluded-files)
  - [Installation](#installation)
    - [Install Dependencies](#install-dependencies)
      - [xmlstarlet:](#xmlstarlet)
      - [rclone:](#rclone)
    - [Install rpie-preservatives](#install-rpie-preservatives)
  - [Disclaimer](#disclaimer)
  - [FAQ](#faq)

## About

rpie-preservatives is a tool to backup and sync save files from retropie to a remote storage system. It started out as just a simple backup tool, but has grown into a tool allowing full save game synchronization across multpiple devices. This allows you to save games across multiple reotropie machines, and or just have a backup in case everything goes pear-shaped.

Since it utilizes rclone, it provides tremendous flexibility, allowing you to choose from a wide variety of remote storage solutions. You can view all the possible providers [here](https://rclone.org/#providers)

rpie-preservatives only saves battery save files (not save states). Save states are quite large to store, and are less stable and flexible overall. I don't have anything against save states, but as far as a backup and synchronization tool is concerned, battery saves are just the way to go.

rpie-preservatives supports many systems, but I can't test them all alone. There may be some systems that sync too many files (the dolphin core for gc and wii and even ppsspp store more than necessary, but the size isn't too great and doesn't take long to sync after initial upload). There may be others in the same boat, but I don't run all systems (and I never will).

## How it works

rpie-preservatives works by processing your es_systems config file to find files that are rom files in your system. It then syncs to rclone excluding the files with extensions it found in es_systems.cfg. It also has a few other files it specifically excludes. You can see them in the list below.

When you run a game through emulationstation, it calls runcommand with a system argument, which in turn calls rpie-preservatives. rpie-preservatives will first sync saved games from the remote to your local file system before launching the game. Once you quit the game, it will then sync any changed files back up to the remote storage. This allows you to run retropie on multiple devices and keep your progress synced across those devices.

### excluded files

- save state files
  - .state
  - .oops
  - .0\*
- scraped info
  - media/\*\*
  - .xml
- translation patch files
  - .ips
  - .ups
  - .bps
- emulator specific files
  - mame\*/\*\*
  - \*\*sd.raw
  - Mupen64plus/\*\*
- others
  - .chd (If you're using chd, you also are probably using .m3u files, so .chd is missing from es_systems.cfg on purpose. If you aren't using .m3u with .chd, you really should be);

If your system does not match these, either update your file system to match this, or modify the scripts to exclude files differently as needed. It's probably easier to modify your file system unless you have programming experience. Even then, if you want to update to later versions of the script, having a matching filesystem will make things easier. I use Skraper beta to scrape with, and this is the default output for scraped data. It's a fantastic skraper. Check it out if you haven't used it yet at [https://www.skraper.net](https://www.skraper.net)

## Installation

### Install Dependencies

#### xmlstarlet:

`sudo apt-get install xmlstarlet`

#### rclone:

in a terminal, run `curl https://rclone.org/install.sh | sudo bash` This will install rclone.

Next, you must configure a remote with rclone. You need to create a remote named `retropie-backup` to work with rpie-preservatives.

Click on the remote storage service you want to use at [https://rclone.org/docs](https://rclone.org/docs) and follow the steps to configure rclone to work with your remote.

### Install rpie-preservatives

Make sure the dependencies are installed before running this.

- Download the archive from releases. Make sure `install.sh` is executable (`chmod +x ./install.sh`) and then run the installer. `./install.sh`.
  - It will ask for your password if you are not root.
- Check your remote store manually at this point to ensure your current save data is stored as you expect. Whatever you see on the remote will become your local file system the next time you run a game through emulationstation once you complete the installation.

From now on, your saves for any given system will be synced every time you run a game for that system.

It would be a good idea to try a system and game that has no saved data first to ensure it uploads and downloads properly before trying a system with saves you care about.

## Disclaimer

rpie-preservatives performs synchronization operations across your file system and the remote storage. Data loss is a real possibility if you do not configure things correctly. Be sure to backup your files and follow **<span style="color: red">ALL</span>** directions carefully to prevent data loss. I'm not responsible for any damage or loss caused to your system by use of these tools.

## FAQ

- What if I already utilize runcommand for other things?
  - That's fine. The commands in the installer only add a command to run these scripts as part of the runcommand scripts. It will not replace anything else in the scripts.
- What if I have poor internet? Can I perform this once a day or once a week instead?
  - In this case you can setup a cronjob to backup as frequently as you need. Don't use the install script. Call it with the upload command and no system and it will backup all systems. Here is an example cron config that will upload saves daily at midnight. `0 0 * * * /opt/retropie/configs/all/rpie-preservatives.sh upload`
- System 'X' doesn't work
  - I've been using this for a while now and it works with all the systems I run. That being said, I don't run all the systems. If there is indeed a problem, report an issue and please provide an example of your files from `~/Retropie/roms/{system}` folder and the relevant tags from `/etc/emulationstation/es_systes.cfg`.
- You \*\*\*\*, I've lost all my save files!
  - rpie-preservatives performs synchronization operations across your file system and the remote storage YOU configured. Data loss is a real possibility, if you do not configure things correctly. Be sure to backup your files and follow ALL directions carefully to prevent data loss.
- I was playing the same game at the same time on two devices and my saves didn't store correctly.
  - This does sync save files, but it can only handle one game at a time. Do not play the same game at the same time and expect both saves to exist. The one you quit last is the one that will be used.
