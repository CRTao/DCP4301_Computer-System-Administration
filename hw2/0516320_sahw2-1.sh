#!/bin/sh
ls -ARl | grep "^[-d]" | sort -rnk 5 | awk 'BEGIN{tsize=0;tdir=0;tfile=0;l=0}{tsize+=$5}/^-/&&l<5{print ++l":",$5,$9}/^-/&&l==5{++tfile}/^d/{tdir++}END{print "Directory Number:",tdir,"\nFile Number:",tfile,"\nTotal Size of Files:",tsize}'
