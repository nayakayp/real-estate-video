if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <FILE_NAME>"
  exit 1
fi

FILENAME="$1"
TEMP_DIR="temp_photos"

# Clean up temporary directory
rm -rf "$TEMP_DIR"

# Remove scene video files
echo "Removing scene video files..."
rm -f scene*.mp4

# Remove concatenated photos video
echo "Removing concatenated photos video..."
rm -f photos.mp4

# Remove input file list
echo "Removing input.txt..."
rm -f input.txt

# Remove final output video
rm -f "${FILENAME}"

echo "Cleanup complete."
