# Key Logic & Pipeline

The wallpaper update process follows these steps:

1. **Environment Check**: Verify if the script is running with root privileges and identify the SRM environment.
2. **Configuration Loading**: Load settings from the script's internal configuration section (defaults and installer-applied values).
3. **Private Workdir**: Create a `mktemp -d` directory (`chmod 700`) for intermediates; remove it via `EXIT` trap (INT/TERM exit after cleanup).
4. **Bing API Interaction**: Fetch the latest wallpaper metadata from Bing's JSON API over TLS for the configured region and resolution (4K/1080p).
5. **URL Validation**: Require an absolute Bing path and reject path tricks (`@`, `://`, `..`) before download.
6. **Image Download**: Download the image with TLS verification into the private workdir.
7. **JPEG Validation**: Confirm JPEG SOI magic bytes before ImageMagick or deployment to system wallpaper files.
8. **Image Processing**: Optionally apply text overlays (Title/Copyright) using ImageMagick and a root-owned font cache.
9. **Resource Discovery**: Locate the SRM wallpaper resource files on the filesystem (dynamically handles different SRM layouts).
10. **Deployment**: Update the login background and system default wallpapers.
11. **Archiving**: (Optional) Save under `SAVE_PATH` using a validated eight-digit Bing date.
