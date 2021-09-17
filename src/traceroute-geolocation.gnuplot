#!/usr/bin/env gunplot
set terminal png medium size 1280,960
set title "TraceRoute GeoLocation Map\n".ARG4
set output ARG3.".png"
unset key
set xrange [-180:180]
set yrange [-90:90]
set yzeroaxis
set xtics geographic
set ytics geographic
set format x "%D %E"
set format y "%D %N"
plot ARG1 with lines lc rgb "blue" , ARG2 using 1:2:3 with labels offset 1,1 tc rgb "brown" font ',12', '' with lines lw 2 lc rgb "red"
set terminal svg size 1280,960
set output ARG3.".svg"
replot
