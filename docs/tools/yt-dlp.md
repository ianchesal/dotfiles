# dotfiles/yt-dlp

Configuration for [yt-dlp](https://github.com/yt-dlp/yt-dlp), a video downloader. The config reads credentials from `~/.netrc`, merges output to mp4, and sets the default format selection. chezmoi copies `home/dot_config/yt-dlp/config` to `~/.config/yt-dlp/config`.

## Tasks

- Config is deployed by chezmoi from `home/dot_config/yt-dlp/`
- `just ytdlp::update` — Update yt-dlp
