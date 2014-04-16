#!/bin/bash
wget -O data/$1 $2 --timeout=10 --tries=5 2>&1> /dev/null | perl -lne '/^Resolving / and not /failed/ and @arr = split(/\s+/,$_) and print $arr[1];'
