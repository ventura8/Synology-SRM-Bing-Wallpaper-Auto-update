# Key Logic & Pipeline

The wallpaper update process follows these steps:

1.  **Environment Check**: Verify if the script is running with root privileges and identify the SRM environment.
2.  **Configuration Loading**: Load settings from the script's internal configuration section or environment variables.
3.  **Bing API Interaction**: Fetch the latest wallpaper metadata from Bing's JSON API for the configured region and resolution (4K/1080p).
4.  **Resource Discovery**: Locate the SRM wallpaper resource files on the filesystem (dynamically handles different SRM layouts).
5.  **Image Processing**: Download the image and optionally apply text overlays (Title/Copyright) using ImageMagick.
6.  **Deployment**: Update the login background and system default wallpapers.
7.  **Archiving**: (Optional) Save the wallpaper to a history directory.
