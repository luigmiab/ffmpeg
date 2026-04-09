#!/bin/bash

# All variables are required — no defaults to keep values private
: ${STREAM_1:?Variable STREAM_1 is required}
: ${STREAM_2:?Variable STREAM_2 is required}
: ${STREAM_3:?Variable STREAM_3 is required}
: ${OUTPUT_FPS:?Variable OUTPUT_FPS is required}
: ${OUTPUT_WIDTH:?Variable OUTPUT_WIDTH is required}
: ${OUTPUT_HEIGHT:?Variable OUTPUT_HEIGHT is required}
: ${HLS_TIME:?Variable HLS_TIME is required}
: ${HLS_LIST_SIZE:?Variable HLS_LIST_SIZE is required}
: ${PRESET:?Variable PRESET is required}

TILE_W=$(( OUTPUT_WIDTH / 2 ))
TILE_H=$(( OUTPUT_HEIGHT / 2 ))

RETRY_DELAY=3
MAX_DELAY=60

while true; do
  ffmpeg -re \
    -i "${STREAM_1}" \
    -i "${STREAM_2}" \
    -i "${STREAM_3}" \
    -filter_complex "
      [0:v]scale=${TILE_W}:${TILE_H},fps=${OUTPUT_FPS}[v0];
      [1:v]scale=${TILE_W}:${TILE_H},fps=${OUTPUT_FPS}[v1];
      [2:v]scale=${TILE_W}:${TILE_H},fps=${OUTPUT_FPS}[v2];
      color=black:size=${TILE_W}x${TILE_H}:rate=${OUTPUT_FPS}[v3];
      [v0][v1][v2][v3]xstack=inputs=4:layout=0_0|w0_0|0_h0|w0_h0[out]
    " \
    -map "[out]" \
    -c:v libx264 -preset "${PRESET}" -r "${OUTPUT_FPS}" -g $(( OUTPUT_FPS * 2 )) \
    -s "${OUTPUT_WIDTH}x${OUTPUT_HEIGHT}" \
    -f hls \
    -hls_time "${HLS_TIME}" \
    -hls_list_size "${HLS_LIST_SIZE}" \
    -hls_flags delete_segments \
    /output/mosaic/index.m3u8
  echo "FFmpeg exited, restarting in ${RETRY_DELAY}s..."
  sleep "${RETRY_DELAY}"
  RETRY_DELAY=$(( RETRY_DELAY * 2 ))
  if [ "${RETRY_DELAY}" -gt "${MAX_DELAY}" ]; then
    RETRY_DELAY="${MAX_DELAY}"
  fi
done
