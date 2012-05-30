@echo off
echo Compiling bconv
rdmd --build-only -Jsrc src\bconv.d

echo Compiling ddis
rdmd --build-only -Jsrc src\ddis.d