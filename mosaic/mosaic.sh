#!/bin/bash
while true; do
  ffmpeg -re \
    -i https://hls.4manager.app/live/pc1/index.m3u8 \
    -i https://hls.4manager.app/live/pc2/index.m3u8 \
    -i https://hls.4manager.app/live/pc3/index.m3u8 \
    -filter_complex "
      [0:v]scale=640:360,fps=60[v0];
      [1:v]scale=640:360,fps=60[v1];
      [2:v]scale=640:360,fps=60[v2];
      color=black:size=640x360:rate=60[v3];
      [v0][v1][v2][v3]xstack=inputs=4:layout=0_0|w0_0|0_h0|w0_h0[out]
    " \
    -map "[out]" \
    -c:v libx264 -preset veryfast -r 60 -g 120 \
    -s 1280x720 \
    -f hls \
    -hls_time 2 \
    -hls_list_size 6 \
    -hls_flags delete_segments \
    /output/mosaic/index.m3u8
  echo "FFmpeg exited, restarting in 3s..."
  sleep 3
done
