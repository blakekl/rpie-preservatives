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

Download the runcommand-onend.sh and runcommand-onstart.sh files and place them in `/opt/retropie/configs/all/`. 
Launch any emulator and exit to create your first backup file. You can find the file from your drive root in a folder called `retropie-backup/srm_saves.tar.gz`

From now on, this file will be updated any time you close a game if the modification timestamp is different from when you started the game.

## How it works
rpie-preservatives works by comparing the modification timestamps of all your save files when a game is launched and whene it is closed. If there is a difference, creates the `.tar.gz` file with the modified timestamp data removed. It then uses rclone to upload to your cloud storage. Rclone performs a hash check before uploading to ensure the files are different. If the files are the same, then no upload will occur.

## FAQ
 - What if I already utilize runcommand for other things?

In that case, rename the files to something else and call them from your own `runcommand-onstart.sh` and `runcommand-onend.sh` files respectively. Be sure to send in the arguments passed into the script. As an example, if I renamed the `-onend.sh` file to `backup_saves.sh`, then I'd add this line to the end of my `runcommand-onend.sh` file.

`/opt/retropie/config/all/backup_saves.sh $@`

 - What if I have poor internet? Can I perform this once a day or once a week instead?

In this case, you really only need the `-onend.sh` script. Download it and rename it, so that it doesn't get run every time a game is closed. Then, you can setup a cronjob to backup as frequently as you like. Without the `runcommand-onstart.sh` file running, rpie-preservatives will also detect a difference and perform the backup.
