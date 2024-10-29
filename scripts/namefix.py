import os
import re

reg = re.compile(r"(.+)\((\d+)\)\.png")
for filename in os.listdir('.'):
    pattern = reg.match(filename)
    if reg.match(filename):
        newname = f"{pattern.group(1)}-{int(pattern.group(2)):03d}.png"
        print(newname)
        os.rename(filename, newname)
