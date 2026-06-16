# dotfiles/yt-dlp

Configuration for [yt-dlp](https://github.com/yt-dlp/yt-dlp), a video downloader. `yt-dlp.conf` reads credentials from `~/.netrc`, merges output to mp4, and sets the default format selection; it is symlinked to `~/.config/yt-dlp/config`.

## Tasks

- `rake ytdlp` — Install yt-dlp configuration
- `rake ytdlp:update` — Update yt-dlp
