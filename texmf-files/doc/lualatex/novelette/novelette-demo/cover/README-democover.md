
# INSTRUCTIONS:

In this folder is image "zombie.jpg". It is miniature sized for the demo,
not for a realistic book size. Any realistic cover image would be
dozens of megabytes.

Process "zombie.jpg" using script "cmyk4nvt". That will create a new image
named "zombie-nvtcNNNNNN.jpg" where the NNNNNN are digits.
This procedure takes awhile.

In file demo-cover.tex, change the \coverimage setting.
Use the new filename, with its jpg extension.

Then process demo-cover.tex with lualatex. It completes quickly.
The PDF has not text, so it has not fonts.

If you view the image "zombie-nvtcNNNNNN.jpg" in an image viewer, its color
rendition will be wrong. It will appear too brightly colored. The same happens
if you view the finished PDF in most PDF readers. The reason is that the
software does not use the correct color transform, when converting CMYK
(the image and the PDF) to RGB (for view on screen). The "softproof" image
will show correct color rendition. In this case, the softproof will look almost
exactly like the original, unprocessed image. But your own cover image may
show more noticeable color shift, depending on its design.

Look carefully, and you will see that the darkest areas of the softproof
are not as dark as in the original image. This emulate the low amount of ink
used by print-on-demand. You will also see that the most colorful areas
are slightly duller in the softproof. This emulates the limited CMYK color space.




