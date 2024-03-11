# File: cmyk4nvt.sh
# Tested with bash, dash, zsh.
# Part of novelette document class, stored in its documentation directory.
# This is a shell script for Linux, OS/X, and Windows 10+ using Linux subsystem.
# Usage: sh cmyk4nvt.sh filename.ext
# where ext is a raster file format such as jpg, png, tif.
# Requires either ImageMagick or GraphicsMagick.

if expr "$1" : "-v" 1>/dev/null 2>&1
then
  echo "cmyk4nvt version 0.0" && exit
fi

if [ -z "$1" ] || expr "$1" : "-h" 1>/dev/null 2>&1
then
  echo "Usage: sh cmyk4nvt.sh imagefilename.ext"
  echo "where extension ext is a raster image filetype, such as png or jpg."
  echo "This script requires either ImageMagick or GraphicsMagick."
  echo "Also requires files srgb.icc and inklimit240.icc, placed in the"
  echo "same directory as the input image."
  echo "Input image may be RGB or RGBA. Not Grayscale, monochrome, or CMYK."
  echo "If input image does not have a color profile, sRGB is assumed."
  echo "Output is imagefilename-nvtcCODE.png"
  echo "This output filename must not be changed. Novelette reads the CODE."
  echo "Output image is CMYK at 240% ink limit, 300 pixels/inch,"
  echo "without private metadata or color profile."
  echo "If you do not like the result, edit the input image, and try again."
  echo "Best results when input is @ 300 pixels/inch, with color profile."
  exit
fi

if expr "$1" : ".*-nvt" 1>/dev/null 2>&1
then
  echo "Error. Input filename must not contain \"-nvt\"."
  echo "To re-process a file that was already processed by this script,"
  echo "change the input file name."
  exit 2
fi

if [ ! -r "$1" ] ; then
  echo "Error. Did not find the input file, or it is not readable."
  exit 2
fi

filedir=$(dirname "$1")
if [ ! -w "$filedir" ] ; then
  echo "Error. The directory containing the input file is not writeable."
  echo "Try moving the file to somewhere in your home directory."
  exit 2
fi

if [ ! -r "$filedir/srgb.icc" ] || [ ! -r "$filedir/inklimit240.icc" ] ; then
  echo "Error. Did not find both srgb.icc and inklimit240.icc in the"
  echo "same dirctory as the input image. Copy them there, then try again."
  exit 2
fi

command -v magick >/dev/null 2>&1
if [ "$?" -ne 0 ] ; then
  command -v gm >/dev/null 2>&1
  if [ "$?" -ne 0 ] ; then
    echo "ERROR. Did not find either ImageMagick or GraphicsMagick."
    exit 2
  else
    echo "Using GraphicsMagick..."
    PROG=gm
  fi
else
  echo "Using ImageMagick..."
  PROG=magick
fi

echo "If you see warning about unknown tag type, ignore it."
printf "Working, be patient..."
FILE="$1"
filebase="${FILE%.*}"
inicc="$filedir/srgb.icc"
$PROG convert "$1" "$filedir/temp-cmyk4nvt.icc" 1>/dev/null 2>/dev/null
if [ "$?" -eq 0 ] ; then
  inicc="$filedir/temp-cmyk4nvt.icc"
else
  rm -f "$filedir/temp-cmyk4nvt.icc"
fi
outicc="$filedir/inklimit240.icc"

args1="-depth 8 -intent relative"
args2="-profile $inicc -profile $outicc"

# No quotes on $args1 or $args2 below:
tmpfile="$filedir/temp-cmyk4nvt.png"
$PROG convert -strip "$1" "$tmpfile"
$PROG convert "$tmpfile" $args1 $args2 "$filedir/temp-cmyk4nvt.tif"
if [ "$?" -ne 0 ] ; then
  echo "Error. Something went wrong. Reason unknown."
  rm -f "$tmpfile"
  rm -f "$filedir/temp-cmyk4nvt.tif"
  exit 2
fi
rm -f "$tmpfile"
tmpfile="$filedir/temp-cmyk4nvt.tif"
args="-quality 100 -density 300 -units PixelsPerInch"
$PROG convert -strip "$tmpfile" $args "$filedir/temp-cmyk4nvt.jpg"
if [ "$?" -ne 0 ] ; then
  echo "Error. Something went wrong. Reason unknown."
  rm -f "$tmpfile"
  rm -f "$filedir/temp-cmyk4nvt.jpg"
  exit 2
fi
rm -f "$tmpfile"

args="-profile $outicc -profile $filedir/srgb.icc"
$PROG convert "$filedir/temp-cmyk4nvt.jpg" $args "$filebase-softproof.jpg"

# Do not circumvent this elementary method for coding the file name.
# If you do that, then your PDF may compile and look OK, but fail validation.
w=$($PROG identify -format %w "$filedir/temp-cmyk4nvt.jpg")
h=$($PROG identify -format %h "$filedir/temp-cmyk4nvt.jpg")
s=$(stat --format %s "$filedir/temp-cmyk4nvt.jpg")
n=$((7654321))
n=$((n+w+h+s))
mv "$filedir/temp-cmyk4nvt.jpg" "$filebase-nvtc$n.jpg"
rm -f "$filedir/temp-cmyk4nvt.icc"
echo "DONE."
echo "Output file: $filebase-nvtc$n.jpg"
echo "Softproof file: $filebase-softproof.jpg"
echo "To see the result, view the sRGB softproof, NOT the CMYK output."

## end of file

