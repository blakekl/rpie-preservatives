# rpie-preservatives

## Table of Contents

- [rpie-preservatives](#rpie-preservatives)
  - [Table of Contents](#table-of-contents)
  - [About](#about)
  - [How it works](#how-it-works)
    - [excluded files](#excluded-files)
  - [Installation](#installation)
    - [Install Dependencies](#install-dependencies)
      - [rclone:](#rclone)
    - [Install rpie-preservatives](#install-rpie-preservatives)
  - [rpie-settings.cfg](#rpie-settingscfg)
  - [Disclaimer](#disclaimer)
  - [FAQ](#faq)

## About

rpie-preservatives is a tool to backup and sync save files from retropie to a remote storage system. It started out as just a simple backup tool, but has grown into a tool allowing full save game synchronization across multiple devices. This allows you to save games across multiple retropie machines, and or just have a backup in case everything goes pear-shaped.

Since it utilizes rclone, it provides tremendous flexibility, allowing you to choose from a wide variety of remote storage solutions. You can view all the possible providers [here](https://rclone.org/#providers)

rpie-preservatives only saves battery save files by default. Save states are quite large to store, and are less stable and flexible. They also are somewhat unreliable overall. There is a config option to sync save states as well, but you will have to manually add it yourself.

rpie-preservatives supports many systems, but I can't test them all alone. There may be some systems that sync too many files (the dolphin core for gc and wii and even ppsspp store more than necessary, but the size isn't too great and doesn't take long to sync after initial upload). There may be others in the same boat, but I don't run all systems (and I never will). If an issue is opened with good details and you're willing to do testing for me, we can add any systems that don't appear to work correctly.

## How it works

rpie-preservatives works by processing your es_systems config file to find files that are rom files in your system. It then syncs to rclone excluding the files with extensions it found in es_systems.cfg. It also has a few other files it specifically excludes. You can see them in the list below.

When you run a game through emulationstation, it calls runcommand with a system argument, which in turn calls rpie-preservatives. rpie-preservatives will first sync saved games from the remote to your local file system before launching the game. Once you quit the game, it will then sync any changed files back up to the remote storage. This allows you to run retropie on multiple devices and keep your progress synced across those devices.

### excluded files

- scraped info
  - media/\*\*
  - .xml
- emulator specific files
  - mame\*/\*\*
  - \*\*sd.raw (this is an sd card file in dolphin for gamecube and wii. It's large)
  - Mupen64plus/\*\*
- others
  - .chd (If you're using chd, you also are probably using .m3u files, so .chd is missing from es_systems.cfg on purpose. If you aren't using .m3u with .chd, you really should be);

If your system does not match these, either update your file system to match this, or modify the scripts to exclude files differently as needed. It's probably easier to modify your file system unless you have programming experience. Even then, if you want to update to later versions of the script, having a matching filesystem will make things easier. I use Skraper beta to scrape with, and this is the default output for scraped data. It's a fantastic skraper. Check it out if you haven't used it yet at [https://www.skraper.net](https://www.skraper.net)

## Installation

### Install Dependencies

#### rclone:

in a terminal, run `curl https://rclone.org/install.sh | sudo bash` This will install rclone.

Next, you must configure a remote with rclone.

Click on the remote storage service you want to use at [https://rclone.org/docs](https://rclone.org/docs) and follow the steps to configure rclone to work with your remote.

### Install rpie-preservatives

Make sure the dependencies are installed before running this.

- Download the archive from releases. Make sure `install.sh` is executable (`chmod +x ./install.sh`) and then run the installer. `./install.sh`.
  - It will ask for your password if you are not root.
- Copy the /opt/retropie/configs/all/rpie-settings.cfg.example file to /opt/retropie/configs/all/rpie-setting.cfg
  - Make any edits to the config file if you don't like the default settings.
  - finally, run `/opt/retropie/configs/all/rpie-preservatives.sh upload` in a terminal. This will execute a full backup of your current saves.
- Check your remote store manually at this point to ensure your current save data is stored as you expect. Whatever you see on the remote will become your local file system the next time you run a game through emulationstation once you complete the installation.

From now on, your saves for any given system will be synced every time you run a game for that system.

It would be a good idea to try a system and game that has no saved data first to ensure it uploads and downloads properly before trying a system with saves you care about.

## rpie-settings.cfg

rpie-settings.cfg is a file that contains various settings for the rpie-preservatives script to use during execution. I suggest starting off by copying rpie-settings.cfg.example -> rpie-settings.cfg. I tried to have reasonable defaults here, but there are some values you may want to look at. 

| setting name     | description                                                                                                                                                                                                                                                                                                                                                                      | default                                | possible values
|------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------|--------------------------------------------------------------------------------|
| es_systems_path  | Path to the es_systems file. Used to parse out game files so they are not stored on the remote. Defaults to the default location in retropie. Included here for people who may not be running a retropie install, but want to use the script on retroarch or something. You will need to copy over a valid es_systems.cfg file to that system, but it's not terribly difficult. For more information see the es_systems.cfg section below.  | "/etc/emulationstation/es_systems.cfg" |any path wrapped in quotes ("")
| rclone_drive     | The rclone drive you setup during installation. It should be in the format "remote:DESTINATION", per the rclone docs.                                                                                                                                                                                                                                                            | "retropie-backup:retropie-backup"      |any value in quotes with a colon surrounded by any other characters.
| roms_path        | The path where the folders for you systems exist. The folder names of the systems should match the system names in the es_systems.cfg file.                                                                                                                                                                                                                                      | "${HOME}/RetroPie/roms"                |any path wrapped in quotes ("")
| sync_patch_files | Whether or not to sync ips, ups, and bps patch files. If "true", backups will be stored on the remote.                                                                                                                                                                                                                                                                           | "false"                                |"true" or "false"
| sync_save_states | Whether or not to sync save state files (.state*,.0*,.oops). If "true" save states will be stored on the remote.                                                                                                                                                                                                                                                                 | "false"                                |"true" or "false"


## es_systems.cfg

### What is it?
The es_systems.cfg file is an XML file used by emulationstation to scan for game files and also configure how the various emulators and roms are launched. As far as this program is concerned, all we care about are the `<name>` and `<extension>` tags. The script essentially scans this document for the matching system name. Your folder containing the roms for this system and the `<name>` tag must match for this to work. It then looks at the `<extension>` tag values. This tag tells emulationstation which file extensions represent the rom files. rpie-preservatives scans your system directory and removes any files that matches the `<extension>` tags extensions from its sync list. All files that don't match the `<extension>` tag or any other global ignores (like `.txt` or `.png`) will be synced to your remote storage.

### What if I'm using this without using emulationstation or retropie?
You can create your own XML file that describes this data and enter that file's path in the rpie-settings.cfg for the `es_systems_path` value. You just need to follow the format described below. Replace anything inside `{}` with the values that fit your data. Extensions are case sensitive.

```
<systemList>
  <system>
    <name>{name of the folder containing the rom for that system. IE nes, snes, or megadrive, etc.}</name>
    <extension>{a space separated list of extensions including the '.'. IE: '.nes .zip .7z'}</extension>
  </system>
</systemList>
```

If this isn't a retropie installation, you can include any other extensions you want to ignore in the extension list too. Don't do this if you are running emulationstation. It will include files you don't intend to in your game list in emulationstation.

Here's a final example, just in case.

```
<systemList>
  <system>
    <name>psx</name>
    <extension>.cue .m3u .chd .CUE .M3U .CHD</extension>
  </system>
  <system>
    <name>snes</name>
    <extension>.sfc .zip .7z .SFC .ZIP .7z</extension>
  </system>
</systemList>
```

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
