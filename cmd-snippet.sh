geomphantoms signals respiratory --duration 10 --fs 100 --rate 12 --out resp.csv

geomphantoms signals cardiac --duration 10 --fs 100 --rate 70 --out cardiac.csv

geomphantoms phantom torso --size 256,256,256 --fov 30,30,30 \
    --resp-signal resp.csv --cardiac-signal cardiac.csv --out torso.mat













