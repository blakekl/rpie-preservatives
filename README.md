# rpie-preservatives
## Installation

First, you must install and setup rclone. This allows you to store your save files on various cloud storage platforms. A full list can be found on the [rclone.org](https://rclone.org) website.

To install rclone, follow the installation steps on their downloads page at [rclone.org/downloads](https://rclone.org/downloads/). If you need help installing, their documentation is pretty clear. Be sure to follow it for the cloud storage system you wish to setup.

*Important*: when setting up rclone, be sure to name the remote `retropie-backup`. I also reccommend using the file permission so that rclone doesn't have access to all your cloud files.

Once rclone is installed, download the runcommand-onend.sh and runcommand-onstart.sh files and place them in `/opt/retropie/configs/all/`. Launch any emulator and exit to create your first backup file. Once this is done, the file will only be uploaded if the timestamps on your save files change. Additionally, timestamps are removed during compression and rclone does a hash comparison to ensure the files are different before uploading. This is a pretty good tradeoff between speed and CPU and bandwidth utilization.
