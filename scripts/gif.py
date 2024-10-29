import sys
import os
from PIL import Image, ImageSequence
 

args = sys.argv[1:]

if len(args) != 1:
    print("Usage: python gif.py <input.gif>")
    sys.exit(1)

name = args[0].split(".")[0]

os.makedirs(name)

# Opening the input gif:
im = Image.open(args[0])
 
# create an index variable:
i = 0
 
# iterate over the frames of the gif:
for fr in ImageSequence.Iterator(im):
    fr.save(f"{name}/{name}-{i:03d}.png")
    i = i + 1
