# Configuration

The main script `bing_wallpaper_auto_update.sh` contains a configuration section:

- `BING_RESOLUTION`: Set to `"4k"` or `"1080p"`.
- `BING_MARKET`: Region code (e.g., `"en-US"`, `"zh-CN"`).
- `ENABLE_ARCHIVE`: `true`/`false` to save wallpaper history.
- `SAVE_PATH`: Directory for archived wallpapers.
- `BURN_TEXT_OVERLAY`: `true`/`false` to overlay metadata on the image.

Environment variables can also be used to override some settings during installation:
- `CRON_HOUR`: Hour for the daily update (0-23).
- `CRON_MIN`: Minute for the daily update (0-59).
- `COVERAGE`: Set to `1` to enable coverage reporting during tests.
