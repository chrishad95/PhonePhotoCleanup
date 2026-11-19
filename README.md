# PhonePhotoCleanup

A menu-driven Bash script for freeing up space taken by photos and videos on an Android phone. It runs in [Termux](https://termux.dev) and works on the camera folder (`DCIM`).

## Setup

Run these in Termux:

```bash
pkg update
pkg install git fzf chafa
termux-setup-storage        # tap Allow; creates ~/storage/shared

git clone https://github.com/chrishad95/PhonePhotoCleanup.git
cd PhonePhotoCleanup
./photo_cleanup.sh
```

- `fzf` is needed for option 8. `chafa` is optional and adds thumbnail previews for jpg and png files in option 8. Other files show size and date only.
- `termux-setup-storage` must be run once, or the script can't see your photos.
- To update later: `cd ~/PhonePhotoCleanup && git pull`.

## Menu options

| # | Option | What it does | Changes files? |
|---|--------|--------------|----------------|
| 1 | Show storage usage | Total size of `DCIM` | No |
| 2 | Largest 100 photos/videos | Lists the 100 biggest files with human-readable sizes | No |
| 3 | Find photos older than N years | Lists files older than the age you enter | No |
| 4 | Find duplicate photos | Hashes every image (SHA-256) and prints groups of identical files | No |
| 5 | Archive old photos | Moves files older than the age you enter to `Pictures/Archive` | **Moves** |
| 6 | Delete files from a list | Shows a list file, asks for `yes`, then deletes every path in it | **Deletes permanently** |
| 7 | Photos by year and month | Table of file count and total size per month, plus a grand total | No |
| 8 | Browse largest 500 files (fzf) | Interactive list of the 500 biggest files. Tab marks files, Enter saves them to `~/delete_list.txt` | No (only writes the list) |
| 9 | Exit | | No |

### Entering an age (options 3 and 5)

The age is in years and can be fractional. All of these work:

| Input | Meaning |
|-------|---------|
| `2` | 2 years |
| `0.5` | 6 months |
| `1/12` | 1 month |
| `1/4` | 3 months |

A year is counted as 365.25 days. Anything else prints an error and returns to the menu.

### Suggested workflow for freeing space

1. Option 7 to see which months take the most space.
2. Option 8 to mark the biggest files you don't need. This saves `~/delete_list.txt`.
3. Option 6, entering the full path `/data/data/com.termux/files/home/delete_list.txt`, to delete them. Don't type `~`, because the prompt does not expand it.

Try options 1, 2, 3, 4, 7 and 8 first. They only read files.

## Things to know

- **Back up first.** Option 6 uses `rm`, so deleted files do not go to a trash. Make sure Google Photos or another backup has them.
- **Dates come from file modification time.** Copying or restoring files can reset this, so a month may look larger than expected. The photo's real capture date is not used.
- **File types.** Options 2, 7 and 8 cover jpg, jpeg, png, heic, mp4 and mov. Option 4 covers images only. Options 3 and 5 match every file type under `DCIM`, including thumbnails and other non-photo files.
- **Option 5 flattens folders.** Everything lands directly in `Pictures/Archive`, and files with the same name may overwrite each other.
- **Option 4 and file names with spaces.** The duplicate report splits on whitespace, so paths containing spaces may print truncated.
- **Gallery apps.** After deleting or moving files, run `termux-media-scan <path>` if the gallery still shows them.
- **Line endings.** The script must use Unix (LF) line endings. A `.gitattributes` file keeps this when committing from Windows.

## Future enhancements

Ideas for a version 2:

- Detect near-duplicate photos (same picture at different resolutions or slight edits) with perceptual hashing, not only exact duplicates.
- Identify blurry photos using image analysis.
- Find screenshots, memes, and downloaded images separately.
- Show a full-screen terminal UI (similar to `htop`): arrow keys to navigate, Space to mark photos, D to delete or M to move.
- Cache hashes and scores in SQLite so repeat scans only process new files.
- Move deleted files to a trash folder instead of removing them.
