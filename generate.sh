#!/bin/bash
# ./generate.sh "g-duren-jakarta-barat-xlbx" "APARTMENT" "Rp 1.5 Miliar" "Jl. Contoh Alamat No. 123" "Jakarta, Selatan, Kebayoran Baru" 3 2 150 "mypropertywebsite.com" "08123456789" "info@mypropertywebsite.com" "https://cdn.brighton.co.id/Uploads/Images/13068350/MfTUVXlb/IMG-20250121-WA0119-watermarked.webp" "https://cdn.brighton.co.id/Uploads/Images/13068348/kZzdb0QA/IMG-20250121-WA0126-watermarked.webp" "https://cdn.brighton.co.id/Uploads/Images/13068349/C6t8wAqy/IMG-20250121-WA0130-watermarked.webp" "https://cdn.brighton.co.id/Uploads/Images/13068346/lqE2RBT9/IMG-20250121-WA0132-watermarked.webp" "https://cdn.brighton.co.id/Uploads/Images/13068347/yPxuKtsY/IMG-20250121-WA0136-watermarked.webp" "https://cdn.brighton.co.id/Uploads/Images/13068352/sV39QsBs/IMG-20250121-WA0131-watermarked.webp" "https://cdn.brighton.co.id/Uploads/Images/13068353/xivbKskM/IMG-20250121-WA0129-watermarked.webp"

# Config

# Check if enough arguments are provided
if [ "$#" -lt 12 ]; then
  echo "Usage: $0 <PROPERTY_TYPE> <PROPERTY_PRICE> <PROPERTY_ADDRESS> <PROPERTY_CITY> <PROPERTY_BEDROOM> <PROPERTY_BATHROOM> <PROPERTY_SQUARE_METER> <PROPERTY_WEBSITE> <PROPERTY_PHONE> <PROPERTY_EMAIL> <PHOTO_URL1> [<PHOTO_URL2> ...]"
  exit 1
fi

# Assign arguments to variables
FILENAME="$1"
PROPERTY_TYPE="$2"
PROPERTY_PRICE="$3"
PROPERTY_ADDRESS="$4"
PROPERTY_CITY="$5"
PROPERTY_BEDROOM="$6"
PROPERTY_BATHROOM="$7"
PROPERTY_SQUARE_METER="$8"
PROPERTY_WEBSITE="$9"
PROPERTY_PHONE="${10}"
PROPERTY_EMAIL="${11}"

# Array to store photo URLs
PHOTO_URLS=()
# Populate PHOTO_URLS array from remaining arguments
for ((i = 12; i <= $#; i++)); do
  PHOTO_URLS+=("${!i}")
done

WIDTH=1080
HEIGHT=1920
IMAGE_DURATION=3

# Create a temporary directory for downloaded photos
TEMP_DIR="temp_photos"
mkdir -p "$TEMP_DIR"

# Download photos from URLs and populate the PHOTOS array
PHOTOS=()
for i in "${!PHOTO_URLS[@]}"; do
  url="${PHOTO_URLS[$i]}"
  filename="$TEMP_DIR/photo$((i + 1)).jpg"
  echo "Downloading $url to $filename"
  curl -s -o "$filename" "$url"
  PHOTOS+=("$filename")
done

VIDEO_DURATION=$((${#PHOTOS[@]} * IMAGE_DURATION))

echo $VIDEO_DURATION

# Step 1: Create photo clips resized & padded with WHITE background, with fade
for i in "${!PHOTOS[@]}"; do
  idx=$((i + 1))
  fade_out_start=$(echo "$IMAGE_DURATION - 0.5" | bc)
  ffmpeg -y -loop 1 -t $IMAGE_DURATION -i "${PHOTOS[$i]}" \
    -vf "crop='min(iw, ih*822/1106)':'min(ih, iw*1106/822)':'(iw - min(iw, ih*822/1106))/2':'(ih - min(ih, iw*1106/822))/2', scale=822:1106, fade=t=in:st=0:d=0.5,fade=t=out:st=$fade_out_start:d=0.5,pad=${WIDTH}:${HEIGHT}:112:378:color=white" \
    -c:v libx264 -t $IMAGE_DURATION -pix_fmt yuv420p "scene$idx.mp4"
done

# Step 2: Concatenate photo scenes
echo -e "$(for i in "${!PHOTOS[@]}"; do echo "file 'scene$((i + 1)).mp4'"; done)" >input.txt
ffmpeg -y -f concat -safe 0 -i input.txt -c copy photos.mp4

# Step 3: Create static overlay using photos video as input with white background and add audio
ffmpeg -y -f lavfi -i color=c=white:s=${WIDTH}x${HEIGHT}:d=$VIDEO_DURATION \
  -i photos.mp4 \
  -i audio.mp3 \
  -filter_complex "\
    [0:v][1:v]overlay=format=auto[bg_with_photos];\
    [bg_with_photos]\
    drawbox=x=198:y=119:w=649:h=372:color=white@1.0:thickness=fill,\
    drawbox=x=198:y=119:w=649:h=372:color=black@1.0:thickness=2,\
    drawtext=fontfile='Georgia':text='Now On':x=357:y=176:fontsize=96:fontcolor=black,\
    drawtext=fontfile='Georgia':text='The Market':x=277:y=272:fontsize=96:fontcolor=black,\
    drawtext=:text='${PROPERTY_TYPE}':x=198+(649-text_w)/2:y=390:fontsize=46:fontcolor=black,\
    drawbox=x=399:y=1325:w=649:h=335:color=black@1.0:thickness=fill,\
    drawbox=x=731:y=1370:w=1:h=243:color=white@1.0:thickness=fill,\
    drawtext=text='DETAIL\:':x=452:y=1370:fontsize=24:fontcolor=#8E8E8E,\
    drawtext=text='HARGA\:':x=920:y=1370:fontsize=24:fontcolor=#8E8E8E,\
    drawtext=text='${PROPERTY_PRICE}':x=380+649-text_w-20:y=1403:fontsize=28:fontcolor=white,\
    drawtext=text='${PROPERTY_BEDROOM} Kamar Tidur':x=448:y=1493:fontsize=28:fontcolor=white,\
    drawtext=text='${PROPERTY_BATHROOM} Kamar Mandi':x=448:y='1493 + 43':fontsize=28:fontcolor=white,\
    drawtext=text='${PROPERTY_SQUARE_METER} m2':x=448:y='1493 + 2 * 43':fontsize=28:fontcolor=white,\
    drawtext=text='${PROPERTY_ADDRESS}':fontsize=18:fontcolor=white:x=w-256-70:y=1545, \
    drawtext=text='Get in touch for details\:':fontsize=28:fontcolor=black:x=112:y=1761, \
    drawtext=text='${PROPERTY_PHONE}':fontsize=24:fontcolor=black:x=1028-text_w:y=1721, \
    drawtext=text='${PROPERTY_WEBSITE}':fontsize=24:fontcolor=black:x=1028-text_w:y=1750, \
    drawtext=text='${PROPERTY_EMAIL}':fontsize=24:fontcolor=black:x=1028-text_w:y=1779, \
    drawtext=text='${PROPERTY_CITY}':fontsize=18:fontcolor=white:x=w-256-70:y=1579[v];\
    [2:a]afade=t=out:st='$((VIDEO_DURATION - 3))':d=3[a]" \
  -map "[v]" \
  -map "[a]" \
  -t $VIDEO_DURATION \
  -c:v libx264 -pix_fmt yuv420p -c:a aac -strict experimental "${FILENAME}.mp4"

echo $PROPERTY_EMAIL
