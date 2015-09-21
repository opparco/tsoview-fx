@echo off
debug\dumptech.exe debug\toonshader.fx.bin > doc\techniques.txt
ruby techmap.rb > debug\techmap.txt
