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

# Monitor interval in seconds (default 15)
MONITOR_INTERVAL=${MONITOR_INTERVAL:-15}

TILE_W=$(( OUTPUT_WIDTH / 2 ))
TILE_H=$(( OUTPUT_HEIGHT / 2 ))

FFMPEG_PID=""
CURRENT_STREAM_KEY=""

check_stream() {
  local url="$1"
  ffprobe -v quiet -i "${url}" -select_streams v:0 \
    -show_entries stream=codec_type \
    -of default=noprint_wrappers=1:nokey=1 2>/dev/null | grep -q video
}

get_active_streams() {
  for var in STREAM_1 STREAM_2 STREAM_3 STREAM_4; do
    local url="${!var}"
    if [ -n "${url}" ] && check_stream "${url}"; then
      echo "${url}"
    fi
  done
}

get_stream_key() {
  # Returns a string that uniquely identifies the current set of active streams
  # Used to detect changes
  local streams=("$@")
  echo "${streams[*]}"
}

run_ffmpeg() {
  local streams=("$@")
  local count=${#streams[@]}

  echo "Starting FFmpeg with ${count} stream(s)..."

  if [ "${count}" -eq 0 ]; then
    ffmpeg -hide_banner -re \
      -f lavfi -i "color=black:size=${OUTPUT_WIDTH}x${OUTPUT_HEIGHT}:rate=${OUTPUT_FPS}" \
      -vf "drawtext=text='Nessun segnale':fontcolor=white:fontsize=48:x=(w-text_w)/2:y=(h-text_h)/2" \
      -c:v libx264 -preset "${PRESET}" -r "${OUTPUT_FPS}" -g $(( OUTPUT_FPS * 2 )) \
      -f hls \
      -hls_time "${HLS_TIME}" \
      -hls_list_size "${HLS_LIST_SIZE}" \
      -hls_flags delete_segments \
      -t "${MONITOR_INTERVAL}" \
      /output/mosaic/index.m3u8 &
    FFMPEG_PID=$!
    return
  fi

  if [ "${count}" -eq 1 ]; then
    ffmpeg -hide_banner -re \
      -i "${streams[0]}" \
      -vf "scale=${OUTPUT_WIDTH}:${OUTPUT_HEIGHT}:force_original_aspect_ratio=decrease,pad=${OUTPUT_WIDTH}:${OUTPUT_HEIGHT}:(ow-iw)/2:(oh-ih)/2:black,fps=${OUTPUT_FPS}" \
      -c:v libx264 -preset "${PRESET}" -r "${OUTPUT_FPS}" -g $(( OUTPUT_FPS * 2 )) \
      -f hls \
      -hls_time "${HLS_TIME}" \
      -hls_list_size "${HLS_LIST_SIZE}" \
      -hls_flags delete_segments \
      /output/mosaic/index.m3u8 &
    FFMPEG_PID=$!
    return
  fi

  if [ "${count}" -eq 2 ]; then
    ffmpeg -hide_banner -re \
      -i "${streams[0]}" \
      -i "${streams[1]}" \
      -filter_complex "
        [0:v]scale=${TILE_W}:${OUTPUT_HEIGHT}:force_original_aspect_ratio=decrease,pad=${TILE_W}:${OUTPUT_HEIGHT}:(ow-iw)/2:(oh-ih)/2:black,fps=${OUTPUT_FPS}[v0];
        [1:v]scale=${TILE_W}:${OUTPUT_HEIGHT}:force_original_aspect_ratio=decrease,pad=${TILE_W}:${OUTPUT_HEIGHT}:(ow-iw)/2:(oh-ih)/2:black,fps=${OUTPUT_FPS}[v1];
        [v0][v1]hstack=inputs=2[out]
      " \
      -map "[out]" \
      -c:v libx264 -preset "${PRESET}" -r "${OUTPUT_FPS}" -g $(( OUTPUT_FPS * 2 )) \
      -s "${OUTPUT_WIDTH}x${OUTPUT_HEIGHT}" \
      -f hls \
      -hls_time "${HLS_TIME}" \
      -hls_list_size "${HLS_LIST_SIZE}" \
      -hls_flags delete_segments \
      /output/mosaic/index.m3u8 &
    FFMPEG_PID=$!
    return
  fi

  if [ "${count}" -eq 3 ]; then
    ffmpeg -hide_banner -re \
      -i "${streams[0]}" \
      -i "${streams[1]}" \
      -i "${streams[2]}" \
      -filter_complex "
        [0:v]scale=${TILE_W}:${TILE_H}:force_original_aspect_ratio=decrease,pad=${TILE_W}:${TILE_H}:(ow-iw)/2:(oh-ih)/2:black,fps=${OUTPUT_FPS}[v0];
        [1:v]scale=${TILE_W}:${TILE_H}:force_original_aspect_ratio=decrease,pad=${TILE_W}:${TILE_H}:(ow-iw)/2:(oh-ih)/2:black,fps=${OUTPUT_FPS}[v1];
        [2:v]scale=${TILE_W}:${TILE_H}:force_original_aspect_ratio=decrease,pad=${TILE_W}:${TILE_H}:(ow-iw)/2:(oh-ih)/2:black,fps=${OUTPUT_FPS}[v2];
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
      /output/mosaic/index.m3u8 &
    FFMPEG_PID=$!
    return
  fi

  if [ "${count}" -ge 4 ]; then
    ffmpeg -hide_banner -re \
      -i "${streams[0]}" \
      -i "${streams[1]}" \
      -i "${streams[2]}" \
      -i "${streams[3]}" \
      -filter_complex "
        [0:v]scale=${TILE_W}:${TILE_H}:force_original_aspect_ratio=decrease,pad=${TILE_W}:${TILE_H}:(ow-iw)/2:(oh-ih)/2:black,fps=${OUTPUT_FPS}[v0];
        [1:v]scale=${TILE_W}:${TILE_H}:force_original_aspect_ratio=decrease,pad=${TILE_W}:${TILE_H}:(ow-iw)/2:(oh-ih)/2:black,fps=${OUTPUT_FPS}[v1];
        [2:v]scale=${TILE_W}:${TILE_H}:force_original_aspect_ratio=decrease,pad=${TILE_W}:${TILE_H}:(ow-iw)/2:(oh-ih)/2:black,fps=${OUTPUT_FPS}[v2];
        [3:v]scale=${TILE_W}:${TILE_H}:force_original_aspect_ratio=decrease,pad=${TILE_W}:${TILE_H}:(ow-iw)/2:(oh-ih)/2:black,fps=${OUTPUT_FPS}[v3];
        [v0][v1][v2][v3]xstack=inputs=4:layout=0_0|w0_0|0_h0|w0_h0[out]
      " \
      -map "[out]" \
      -c:v libx264 -preset "${PRESET}" -r "${OUTPUT_FPS}" -g $(( OUTPUT_FPS * 2 )) \
      -s "${OUTPUT_WIDTH}x${OUTPUT_HEIGHT}" \
      -f hls \
      -hls_time "${HLS_TIME}" \
      -hls_list_size "${HLS_LIST_SIZE}" \
      -hls_flags delete_segments \
      /output/mosaic/index.m3u8 &
    FFMPEG_PID=$!
    return
  fi
}

monitor_loop() {
  while true; do
    sleep "${MONITOR_INTERVAL}"
    local new_streams
    mapfile -t new_streams < <(get_active_streams)
    local new_key
    new_key=$(get_stream_key "${new_streams[@]}")

    if [ "${new_key}" != "${CURRENT_STREAM_KEY}" ]; then
      echo "Stream change detected: [${CURRENT_STREAM_KEY}] -> [${new_key}]"
      if [ -n "${FFMPEG_PID}" ] && kill -0 "${FFMPEG_PID}" 2>/dev/null; then
        echo "Killing FFmpeg PID ${FFMPEG_PID}..."
        kill "${FFMPEG_PID}"
      fi
    fi
  done
}

mkdir -p /output/mosaic

# Start monitor loop in background
monitor_loop &
MONITOR_PID=$!

# Trap to kill monitor on exit
trap 'kill ${MONITOR_PID} 2>/dev/null' EXIT

# Main loop
while true; do
  mapfile -t ACTIVE_STREAMS < <(get_active_streams)
  CURRENT_STREAM_KEY=$(get_stream_key "${ACTIVE_STREAMS[@]}")

  run_ffmpeg "${ACTIVE_STREAMS[@]}"

  # Wait for FFmpeg to finish (crash, SIGTERM from monitor, or natural end)
  wait "${FFMPEG_PID}"
  echo "FFmpeg exited, restarting..."
done
