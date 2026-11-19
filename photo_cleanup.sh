#!/data/data/com.termux/files/usr/bin/bash

PHOTO_DIR="$HOME/storage/shared/DCIM"
ARCHIVE_DIR="$HOME/storage/shared/Pictures/Archive"

mkdir -p "$ARCHIVE_DIR"

pause() {
    read -p "Press Enter to continue..."
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
echo "7) Exit"
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
read -p "Older than how many years? " years

days=$((years*365))

find "$PHOTO_DIR" \
    -type f \
    -mtime +$days

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
read -p "Archive photos older than how many years? " years

days=$((years*365))

find "$PHOTO_DIR" \
    -type f \
    -mtime +$days \
    -exec mv -v {} "$ARCHIVE_DIR" \;

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
exit
;;

*)
echo "Invalid choice"
pause
;;

esac

done
