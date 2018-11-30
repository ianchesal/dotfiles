function postprocess-torrent
  set -l tordir $argv[1]
  set -l heredir (pwd)

  printf "Post-Processing: %s\n" $tordir

  if not test -d "$tordir"
    printf "Unable to find torrent directory: %s\n" $tordir
    return 1
  end

  filebot \
    -script fn:amc \
    --output "/Volumes/estore1/Media Drive/Sorted" \
    --action duplicate \
    --conflict auto \
    -non-strict \
    --log-file "/Volumes/estore1/Media Drive/Torrents/Completed/amc.log" \
    --def \
    minFileSize=0 \
    minLengthMS=0 \
    unsorted=y \
    music=y \
    artwork=n \
    excludeList=".excludes" \
    subtitles=en \
    ut_dir="$heredir/$tordir" \
    ut_kind="multi" \
    ut_title="$tordir" \
    ut_label="N/A"

  if test $status -eq 0
    terminal-notifier -title "Torrent Post-Processing Complete" -subtitle "$tordir" -message "Successfully post-processed $tordir"
  end
end
