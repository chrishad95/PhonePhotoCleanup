#!/data/data/com.termux/files/usr/bin/bash

PHOTO_DIR="$HOME/storage/shared/DCIM"
ARCHIVE_DIR="$HOME/storage/shared/Pictures/Archive"

mkdir -p "$ARCHIVE_DIR"

pause() {
    read -p "Press Enter to continue..."
}

# Lists photo/video files with a printf format, e.g. media_find "%s\t%p\n"
media_find() {
    find "$PHOTO_DIR" \
        -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
           -o -iname "*.heic" -o -iname "*.mp4" -o -iname "*.mov" \) \
        -printf "$1"
}

while true
do
clear
echo "=============================="
echo " Android Photo Cleanup Tool"
echo "=============================="
echo
echo "1) Show storage usage"
echo "2) Largest 100 photos/videos"
echo "3) Find photos older than N years"
echo "4) Find duplicate photos"
echo "5) Archive old photos"
echo "6) Delete files from a list"
echo "7) Photos by year and month"
echo "8) Browse largest 500 files (fzf)"
echo "9) Exit"
echo

read -p "Choice: " choice

case $choice in

1)
echo
du -sh "$PHOTO_DIR"
pause
;;

2)
find "$PHOTO_DIR" \
    -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
       -o -iname "*.heic" -o -iname "*.mp4" -o -iname "*.mov" \) \
    -printf "%s %p\n" |
sort -nr |
head -100 |
numfmt --to=iec
pause
;;

3)
read -p "Older than how many years? (e.g. 2, 0.5, 1/12) " years

if mins=$(echo "$years" | awk '
/^[0-9]+(\.[0-9]+)?$/ { printf "%d", $0 * 365.25 * 1440; ok=1; next }
/^[0-9]+(\.[0-9]+)?\/[0-9]+(\.[0-9]+)?$/ {
    split($0, a, "/")
    if (a[2] + 0 == 0) exit 1
    printf "%d", a[1] / a[2] * 365.25 * 1440
    ok=1
    next
}
END { if (!ok) exit 1 }'); then
    find "$PHOTO_DIR" \
        -type f \
        -mmin +$mins
else
    echo "Invalid number. Use a number like 2, 0.5, or a fraction like 1/12."
fi

pause
;;

4)
echo "Scanning for duplicates..."
find "$PHOTO_DIR" \
    -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.heic" \) \
    -exec sha256sum {} \; |
sort |
awk '
{
if ($1==lasthash)
{
print lastfile
print $2
print ""
}
lasthash=$1
lastfile=$2
}'
pause
;;

5)
read -p "Archive photos older than how many years? (e.g. 2, 0.5, 1/12) " years

if mins=$(echo "$years" | awk '
/^[0-9]+(\.[0-9]+)?$/ { printf "%d", $0 * 365.25 * 1440; ok=1; next }
/^[0-9]+(\.[0-9]+)?\/[0-9]+(\.[0-9]+)?$/ {
    split($0, a, "/")
    if (a[2] + 0 == 0) exit 1
    printf "%d", a[1] / a[2] * 365.25 * 1440
    ok=1
    next
}
END { if (!ok) exit 1 }'); then
    find "$PHOTO_DIR" \
        -type f \
        -mmin +$mins \
        -exec mv -v {} "$ARCHIVE_DIR" \;
else
    echo "Invalid number. Use a number like 2, 0.5, or a fraction like 1/12."
fi

pause
;;

6)
read -p "Enter filename containing paths to delete: " file

if [ -f "$file" ]; then
    cat "$file"
    echo
    read -p "Delete ALL of these? (yes/no): " ans

    if [ "$ans" = "yes" ]; then
        xargs -d '\n' rm -v < "$file"
    fi
fi

pause
;;

7)
echo
echo "Month     Files        Size"
echo "-------  ------  ----------"
media_find "%TY-%Tm %s\n" |
awk '
function human(b,   i, u) {
    split("B K M G T", u, " ")
    for (i = 1; b >= 1024 && i < 5; i++) b /= 1024
    return sprintf("%.1f%s", b, u[i])
}
{ count[$1]++; size[$1] += $2; tc++; ts += $2 }
END {
    for (m in count) printf "%-7s  %6d  %10s\n", m, count[m], human(size[m]) | "sort"
    close("sort")
    print "-------  ------  ----------"
    printf "%-7s  %6d  %10s\n", "Total", tc, human(ts)
}'
pause
;;

8)
if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf is not installed. Run: pkg install fzf"
    pause
else
    LIST="$HOME/delete_list.txt"
    media_find "%s\t%p\n" |
    sort -nr |
    head -500 |
    awk -F'\t' -v dir="$PHOTO_DIR/" '
    function human(b,   i, u) {
        split("B K M G T", u, " ")
        for (i = 1; b >= 1024 && i < 5; i++) b /= 1024
        return sprintf("%.1f%s", b, u[i])
    }
    { printf "%s\t%s\t%s\n", human($1), substr($2, length(dir) + 1), $2 }' |
    fzf --multi \
        --layout=reverse \
        --delimiter=$'\t' \
        --with-nth=1,2 \
        --header="Tab=mark  Enter=save list  Esc=cancel" \
        --preview-window=down:40%:wrap \
        --preview='ls -lh {3}; case {3} in *.[jJ][pP][gG]|*.[jJ][pP][eE][gG]|*.[pP][nN][gG]) command -v chafa >/dev/null 2>&1 && chafa -s 40x20 {3} 2>/dev/null;; esac' |
    cut -f3 > "$LIST.tmp"

    if [ -s "$LIST.tmp" ]; then
        mv "$LIST.tmp" "$LIST"
        echo "Saved $(wc -l < "$LIST") file(s) to $LIST"
        echo "Use option 6 and enter that filename to delete them."
    else
        rm -f "$LIST.tmp"
        echo "Nothing selected."
    fi
    pause
fi
;;

9)
exit
;;

*)
echo "Invalid choice"
pause
;;

esac

done
