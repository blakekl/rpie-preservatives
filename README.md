# rpie-preservatives

## Table of Contents

- [rpie-preservatives](#rpie-preservatives)
  - [Table of Contents](#table-of-contents)
  - [About](#about)
  - [How it works](#how-it-works)
    - [excluded files](#excluded-files)
  - [Disclaimer](#disclaimer)
  - [Installation](#installation)
    - [Install Dependencies](#install-dependencies)
      - [xmlstarlet:](#xmlstarlet)
      - [rclone:](#rclone)
    - [Install rpie-preservatives](#install-rpie-preservatives)
  - [FAQ](#faq)

## About

rpie-preservatives is a tool to backup and sync save files from retropie to a remote storage system. It started out as just a simple backup tool, but has grown into a tool allowing full save game synchronization across multpiple devices. This allows you to save games across multiple reotropie machines, and or just have a backup in case everything goes pear-shaped.

Since it utulizes rclone, it provides tremendous flexibility, allowing you to choose from a wide variety of remote storage solutions. You can view all the possible providers [here](https://rclone.org/#providers)

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

## Disclaimer

rpie-preservatives performs synchronization operations across your file system and the remote storage. Data loss is a real possibility if you do not configure things correctly. Be sure to backup your files and follow **<span style="color: red">ALL</span>** directions carefully to prevent data loss. I'm not responsible for any damage or loss caused to your system by use of these tools.

## Installation

### Install Dependencies

#### xmlstarlet:

`sudo apt-get install xmlstarlet`

#### rclone:

Follow the steps on [rclone.org](https://rclone.org/downloads/) if the below doesn't work.

`curl https://rclone.org/install.sh | sudo bash`

Next you'll need to run `rclone config` to setup you're interface to the remote storage system.

- **<span style="color: red">Be sure to name your remote</span>** `retropie-backup`

The below example is for setting up google drive.

```
> rclone config
No remotes found - make a new one
n) New remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
n/r/c/s/q> n
name> retropie-backup
Type of storage to configure.
Choose a number from below, or type in your own value
[snip]
XX / Google Drive
   \ "drive"
[snip]
Storage> drive
Google Application Client Id - leave blank normally.
client_id>
Google Application Client Secret - leave blank normally.
client_secret>
Scope that rclone should use when requesting access from drive.
Choose a number from below, or type in your own value
 1 / Full access all files, excluding Application Data Folder.
   \ "drive"
 2 / Read-only access to file metadata and file contents.
   \ "drive.readonly"
   / Access to files created by rclone only.
 3 | These are visible in the drive website.
   | File authorization is revoked when the user deauthorizes the app.
   \ "drive.file"
   / Allows read and write access to the Application Data folder.
 4 | This is not visible in the drive website.
   \ "drive.appfolder"
   / Allows read-only access to file metadata but
 5 | does not allow any access to read or download file content.
   \ "drive.metadata.readonly"
scope> 3
ID of the root folder - leave blank normally.  Fill in to access "Computers" folders. (see docs).
root_folder_id>
Service Account Credentials JSON file path - needed only if you want use SA instead of interactive login.
service_account_file>
Remote config
Use auto config?
 * Say Y if not sure
 * Say N if you are working on a remote or headless machine or Y didn't work
y) Yes
n) No
y/n> y
If your browser doesn't open automatically go to the following link: http://127.0.0.1:53682/auth
Log in and authorize rclone for access
Waiting for code...
Got code
Configure this as a team drive?
y) Yes
n) No
y/n> n
--------------------
[remote]
client_id =
client_secret =
scope = drive.file
root_folder_id =
service_account_file =
token = {"access_token":"XXX","token_type":"Bearer","refresh_token":"XXX","expiry":"2014-03-16T13:57:58.955387075Z"}
--------------------
y) Yes this is OK
e) Edit this remote
d) Delete this remote
y/e/d> y
```

**Important**: when setting up rclone, be sure to name the remote `retropie-backup`. I also reccommend using the `drive.file` permission so that rclone doesn't have access to all your remote files, but this is up to you.

### Install rpie-preservatives

- Download the `rpie-preservatives.sh` script and place it in `/opt/retropie/configs/all/`
- run the following in a terminal ```sudo chmod +x /opt/retropie/configs/all/rpie-preservatievs.sh && \
  echo './rpie-preservatives.sh upload $1 $2 $3 $4` >> /opt/retropie/configs/all/runcommand-onend.sh' && \
  echo './rpie-preservatives.sh download $1 $2 $3 $4` >> /opt/retropie/configs/all/runcommand-onstart.sh' && \
  /opt/retropie/configs/all/rpie-preservatives.sh upload```
  - This creates your first backup on the remote and sets up rpie-preservatives to run when launching and quitting a game. It will download all the saves for a system when starting a game and uploade them when quitting.
- Check your remote store manually at this point to ensure your current save data is stored as you expect. Whatever you see on the remote will become your local file system the next time you run a game through emulationstation once you complete the installation.

From now on, your saves for any given system will be synced every time you run a game for that system.

It would be a good idea to try a system and game that has no saved data first to ensure it uploads and downloads properly before moving to "critical" systems.

## FAQ

- What if I already utilize runcommand for other things?
  - That's fine. The commands in the installer only add a command to run these scripts as part of the runcommand scripts. It will not replace anything else in the scripts.
- What if I have poor internet? Can I perform this once a day or once a week instead?
  - In this case you can setup a cronjob to backup as frequently as you need. Call it with the upload command and no system and it will backup all systems. Here is an example cron config that will upload saves daily at midnight. `0 0 * * * /opt/retropie/configs/all/rpie-preservatives.sh upload`
- System 'X' doesn't work
  - I've been using this for a while now and it works with all the systems I run. That being said, I don't run all the systems. If there is indeed a problem, report an issue and please provide an example of your files from `~/Retropie/roms/{system}` folder and the relevant tags from `/etc/emulationstation/es_systes.cfg`.
- You \*\*\*\*, I've lost all my save files!
  - rpie-preservatives performs synchronization operations across your file system and the remote storage YOU configured. Data loss is a real possibility, if you do not configure things correctly. Be sure to backup your files and follow ALL directions carefully to prevent data loss.
- I was playing the same game at the same time on two devices and my saves didn't store correctly.
  - This does sync save files, but it can only handle one game at a time. Do not play the same game at the same time and expect both saves to exist. The one you quit last is the one that will be used.

