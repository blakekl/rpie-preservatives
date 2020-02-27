# rpie-preservatives

## Installation

### Install Dependencies

Follow the steps on [rclone.org](https://rclone.org/downloads/) if the below doesn't work.

`curl https://rclone.org/install.sh | sudo bash`

Next you'll need to run `rclone config` to setup you're interface to the cloud storage system.

- **Be sure to name your remote `retropie-backup`**

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

**Important**: when setting up rclone, be sure to name the remote `retropie-backup`. I also reccommend using the `drive.file` permission so that rclone doesn't have access to all your cloud files, but this is up to you.

### Install rpie-preservatives

- Download the `rpie-preservatives-onend.sh` and `rpie-preservatives-onstart.sh` files and place them in `/opt/retropie/configs/all/`.
- Be sure they are executable by running `chmod +x /opt/retropie/configs/all/rpie-preservatives*`.
- run this in a terminal `echo "source /opt/retropie/configs/all/rpie-preservatives-onstart.sh" >> /opt/retropie/configs/all/runcommand-onstart.sh && echo "source /opt/retropie/configs/all/rpie-preservatives-onend.sh" >> /opt/retropie/configs/all/runcommand-onend.sh`
- Launch any emulator and exit to create your first backup file. You can find the files from your drive root in a folder called `retropie-backup`

From now on, these files will be updated any time you close a game and have made changes to your save files (Some systems skip the difference check and will upload every time).

## How it works

rpie-preservatives works by comparing the modification timestamps of all your save files when a game is launched and whene it is closed. If there is a difference, it creates the `.tar.gz` file with the modified timestamp data removed. It then uses rclone to upload to your cloud storage. Rclone performs a hash check before uploading to ensure the files are different. If the files are the same, then no upload will occur.

Currently, the scripts handles backing up any cores that store their saves in `.srm` files. It also supports the following cores that do not store saves in `.srm` files.

- ppsspp
- lr-dolphin (gamecube and wii. Saves backed up separately for each system).
- reicast
- flycast (May not work with per-game save option enabled. I just found out about the option and haven't discovered how it works yet. Hopefully it just uses .srm files in the roms directory like most lr- cores).

## FAQ

- What if I already utilize runcommand for other things?

That's fine. The commands in the installer only add a command to run these scripts as part of the runcommand scripts. It will not replace anything else in the scripts.

- What if I have poor internet? Can I perform this once a day or once a week instead?

In this case, you really only need the `-onend.sh` script. Download it to wherever you like. Then, you can setup a cronjob to backup as frequently as you need. Be sure to pass in a system variable that corresponsd to the system you want backed up.
i.e. `psp` or `gc` or `snes` for example.
