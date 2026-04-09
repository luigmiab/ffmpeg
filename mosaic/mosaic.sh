#!/bin/bash

# Technical variables — required
: ${OUTPUT_FPS:?Variable OUTPUT_FPS is required}
: ${OUTPUT_WIDTH:?Variable OUTPUT_WIDTH is required}
: ${OUTPUT_HEIGHT:?Variable OUTPUT_HEIGHT is required}
: ${HLS_TIME:?Variable HLS_TIME is required}
: ${HLS_LIST_SIZE:?Variable HLS_LIST_SIZE is required}
: ${PRESET:?Variable PRESET is required}

# Stream variables — all optional
# STREAM_1, STREAM_2, STREAM_3, STREAM_4

TILE_W=$(( OUTPUT_WIDTH / 2 ))
TILE_H=$(( OUTPUT_HEIGHT / 2 ))
CHECK_INTERVAL=5

check_stream() {
  local url="$1"
  ffprobe -v quiet -i "${url}" -select_streams v:0 \
    -show_entries stream=codec_type \
    -of default=noprint_wrappers=1:nokey=1 2>/dev/null | grep -q video
}

build_and_run() {
  local streams=()
  for var in STREAM_1 STREAM_2 STREAM_3 STREAM_4; do
    local url="${!var}"
    if [ -n "${url}" ]; then
      echo "Checking ${var}..."
      if check_stream "${url}"; then
        echo "${var} is online"
        streams+=("${url}")
      else
        echo "${var} is offline or unreachable"
      fi
    fi
  done

  local count=${#streams[@]}
  echo "Active streams: ${count}"

  if [ "${count}" -eq 0 ]; then
    echo "No streams available, showing black screen..."
    ffmpeg -re \
      -f lavfi -i "color=black:size=${OUTPUT_WIDTH}x${OUTPUT_HEIGHT}:rate=${OUTPUT_FPS}" \
      -vf "drawtext=text='Nessun segnale':fontcolor=white:fontsize=48:x=(w-text_w)/2:y=(h-text_h)/2" \
      -c:v libx264 -preset "${PRESET}" -r "${OUTPUT_FPS}" -g $(( OUTPUT_FPS * 2 )) \
      -f hls \
      -hls_time "${HLS_TIME}" \
      -hls_list_size "${HLS_LIST_SIZE}" \
      -hls_flags delete_segments \
      -t "${CHECK_INTERVAL}" \
      /output/mosaic/index.m3u8
    return
  fi

  if [ "${count}" -eq 1 ]; then
    echo "1 stream — fullscreen"
    ffmpeg -re \
      -i "${streams[0]}" \
      -vf "scale=${OUTPUT_WIDTH}:${OUTPUT_HEIGHT},fps=${OUTPUT_FPS}" \
      -c:v libx264 -preset "${PRESET}" -r "${OUTPUT_FPS}" -g $(( OUTPUT_FPS * 2 )) \
      -f hls \
      -hls_time "${HLS_TIME}" \
      -hls_list_size "${HLS_LIST_SIZE}" \
      -hls_flags delete_segments \
      /output/mosaic/index.m3u8
    return
  fi

  if [ "${count}" -eq 2 ]; then
    echo "2 streams — side by side"
    ffmpeg -re \
      -i "${streams[0]}" \
      -i "${streams[1]}" \
      -filter_complex "
        [0:v]scale=${TILE_W}:${OUTPUT_HEIGHT},fps=${OUTPUT_FPS}[v0];
        [1:v]scale=${TILE_W}:${OUTPUT_HEIGHT},fps=${OUTPUT_FPS}[v1];
        [v0][v1]hstack=inputs=2[out]
      " \
      -map "[out]" \
      -c:v libx264 -preset "${PRESET}" -r "${OUTPUT_FPS}" -g $(( OUTPUT_FPS * 2 )) \
      -s "${OUTPUT_WIDTH}x${OUTPUT_HEIGHT}" \
      -f hls \
      -hls_time "${HLS_TIME}" \
      -hls_list_size "${HLS_LIST_SIZE}" \
      -hls_flags delete_segments \
      /output/mosaic/index.m3u8
    return
  fi

  if [ "${count}" -eq 3 ]; then
    echo "3 streams — 2x2 with black bottom-right"
    ffmpeg -re \
      -i "${streams[0]}" \
      -i "${streams[1]}" \
      -i "${streams[2]}" \
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
    return
  fi

  if [ "${count}" -ge 4 ]; then
    echo "4 streams — full 2x2 mosaic"
    ffmpeg -re \
      -i "${streams[0]}" \
      -i "${streams[1]}" \
      -i "${streams[2]}" \
      -i "${streams[3]}" \
      -filter_complex "
        [0:v]scale=${TILE_W}:${TILE_H},fps=${OUTPUT_FPS}[v0];
        [1:v]scale=${TILE_W}:${TILE_H},fps=${OUTPUT_FPS}[v1];
        [2:v]scale=${TILE_W}:${TILE_H},fps=${OUTPUT_FPS}[v2];
        [3:v]scale=${TILE_W}:${TILE_H},fps=${OUTPUT_FPS}[v3];
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
    return
  fi
}

mkdir -p /output/mosaic

while true; do
  build_and_run
  echo "Cycle ended, restarting in ${CHECK_INTERVAL}s..."
  sleep "${CHECK_INTERVAL}"
done
