# File: mono4nvt.sh
# Tested with bash, dash, zsh.
# Part of novelette document class, stored in its documentation directory.
# This is a shell script for Linux, OS/X, and Windows 10+ using Linux subsystem.
# Usage: sh mono4nvt filename.ext
# Requires either ImageMagick or GraphicsMagick.

if expr "$1" : "-v" 1>/dev/null 2>&1
then
  echo "mono4nvt version 0.0" && exit
fi

if [ -z "$1" ] || expr "$1" : "-" 1>/dev/null 2>&1
then
  echo "Usage: sh mono4nvt.sh imagefilename.ext"
  echo "where extension ext is a raster image filetype, such as png or jpg."
  echo "This script requires either ImageMagick or GraphicsMagick."
  echo "Input image may be RGB, RGBA, Grayscale, or monochrome. Not CMYK."
  echo "Output is imagefilename-nvtmCODE.png"
  echo "This output filename must not be changed. Novelette reads the CODE."
  echo "Output image is monochrome black/white, 1-bit/pixel, no transparency,"
  echo "600 pixels/inch, without private metadata or color profile."
  echo "If you do not like the result, edit the input image, and try again."
  echo "Best results when input is already black/white @ 600 pixels/inch."
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

printf "Working..."
FILE="$1"
filebase="${FILE%.*}"
args1="-monochrome -density 236.22 -units PixelsPerCentimeter"
args2="-define PNG:exclude-chunk=gAMA,bKGD,zTXt,iTXt,tEXt"
$PROG convert -strip -flatten "$FILE" temp-mono4nvt.png
$PROG mogrify $args1 $args2 temp-mono4nvt.png # No quotes on $args.
# Do not circumvent this elementary method for coding the file name.
# If you do that, then your PDF may compile and look OK, but fail validation.
w=$($PROG identify -format %w temp-mono4nvt.png)
h=$($PROG identify -format %h temp-mono4nvt.png)
s=$(stat --format %s temp-mono4nvt.png)
n=$((123456))
n=$((n+w+h+s))
mv temp-mono4nvt.png "$filebase-nvtm$n.png"
echo "DONE. Output: $filebase-nvtm$n.png"

## end of file

