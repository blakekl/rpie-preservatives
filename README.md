# rpie-preservatives

## Table of Contents

- [rpie-preservatives](#rpie-preservatives)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
    - [Install Dependencies](#install-dependencies)
      - [xmlstarlet:](#xmlstarlet)
      - [rclone:](#rclone)
    - [Install rpie-preservatives](#install-rpie-preservatives)
  - [How it works](#how-it-works)
    - [excluded files](#excluded-files)
  - [FAQ](#faq)

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

- Download the `rpie-preservatives-onend.sh` and `rpie-preservatives-onstart.sh` files from [releases](https://github.com/blakekl/rpie-preservatives/releases) and place them in `/opt/retropie/configs/all/`.
- Be sure they are executable by running `chmod +x /opt/retropie/configs/all/rpie-preservatives*`.
- execute the following in a terminal to create your first backup of your saved games `/opt/retropie/configs/all/rpie-preservatives-onend.sh`
  - <span style="color: red">DO NOT SKIP THIS STEP.</span> If you do, you may lose all your saved games.
- Finally, setup rpie-preservatives to run with runcommand by typing this in a terminal `echo "source /opt/retropie/configs/all/rpie-preservatives-onstart.sh" >> /opt/retropie/configs/all/runcommand-onstart.sh && echo "source /opt/retropie/configs/all/rpie-preservatives-onend.sh" >> /opt/retropie/configs/all/runcommand-onend.sh`

From now on, your saves for any given system will be synced every time you run a game for that system.

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

## FAQ

- What if I already utilize runcommand for other things?

  - That's fine. The commands in the installer only add a command to run these scripts as part of the runcommand scripts. It will not replace anything else in the scripts.

- What if I have poor internet? Can I perform this once a day or once a week instead?

  - In this case, you really only need the `-onend.sh` script. Download it to wherever you like. Then, you can setup a cronjob to backup as frequently as you need. If you call it without any arguments, it will backup all saves for all systems. Here is an example cron config that will upload saves daily at midnight. `0 0 * * * /opt/retropie/configs/all/rpie-preservatives-onend.sh`
