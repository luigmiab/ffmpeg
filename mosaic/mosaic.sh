#!/bin/bash

# Technical variables are required
: ${OUTPUT_FPS:?Variable OUTPUT_FPS is required}
: ${OUTPUT_WIDTH:?Variable OUTPUT_WIDTH is required}
: ${OUTPUT_HEIGHT:?Variable OUTPUT_HEIGHT is required}
: ${HLS_TIME:?Variable HLS_TIME is required}
: ${HLS_LIST_SIZE:?Variable HLS_LIST_SIZE is required}
: ${PRESET:?Variable PRESET is required}

# Stream variables are all optional
# STREAM_1, STREAM_2, STREAM_3, STREAM_4 — set any combination

TILE_W=$(( OUTPUT_WIDTH / 2 ))
TILE_H=$(( OUTPUT_HEIGHT / 2 ))

CHECK_INTERVAL=30  # seconds between stream availability checks
RETRY_DELAY=3
MAX_DELAY=60

# Check if a stream URL is reachable and has video
check_stream() {
  local url="$1"
  if [ -z "$url" ]; then
    return 1
  fi
  ffprobe -v quiet -select_streams v:0 -show_entries stream=codec_type \
    -of default=noprint_wrappers=1:nokey=1 \
    -timeout 5000000 "$url" 2>/dev/null | grep -q "video"
  return $?
}

# Build and run FFmpeg dynamically based on active streams
run_mosaic() {
  # Collect active streams
  local active=()
  for var in STREAM_1 STREAM_2 STREAM_3 STREAM_4; do
    local url="${!var}"
    if check_stream "$url"; then
      echo "[mosaic] $var is ONLINE: $url"
      active+=("$url")
    else
      if [ -n "$url" ]; then
        echo "[mosaic] $var is OFFLINE or unreachable"
      fi
    fi
  done

  local count=${#active[@]}
  echo "[mosaic] Active streams: $count"

  local inputs=()
  local filter_complex=""
  local map_arg=""

  if [ "$count" -eq 0 ]; then
    # No streams — output a black screen with text
    echo "[mosaic] No streams active, showing black screen"
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

  elif [ "$count" -eq 1 ]; then
    # 1 stream — fullscreen
    echo "[mosaic] Layout: fullscreen"
    ffmpeg -re \
      -i "${active[0]}" \
      -filter_complex "[0:v]scale=${OUTPUT_WIDTH}:${OUTPUT_HEIGHT},fps=${OUTPUT_FPS}[out]" \
      -map "[out]" \
      -c:v libx264 -preset "${PRESET}" -r "${OUTPUT_FPS}" -g $(( OUTPUT_FPS * 2 )) \
      -s "${OUTPUT_WIDTH}x${OUTPUT_HEIGHT}" \
      -f hls \
      -hls_time "${HLS_TIME}" \
      -hls_list_size "${HLS_LIST_SIZE}" \
      -hls_flags delete_segments \
      -t "${CHECK_INTERVAL}" \
      /output/mosaic/index.m3u8
    return

  elif [ "$count" -eq 2 ]; then
    # 2 streams — side by side 50/50
    echo "[mosaic] Layout: side by side"
    ffmpeg -re \
      -i "${active[0]}" \
      -i "${active[1]}" \
      -filter_complex "
        [0:v]scale=${TILE_W}:${OUTPUT_HEIGHT},fps=${OUTPUT_FPS}[v0];
        [1:v]scale=${TILE_W}:${OUTPUT_HEIGHT},fps=${OUTPUT_FPS}[v1];
        [v0][v1]xstack=inputs=2:layout=0_0|w0_0[out]
      " \
      -map "[out]" \
      -c:v libx264 -preset "${PRESET}" -r "${OUTPUT_FPS}" -g $(( OUTPUT_FPS * 2 )) \
      -s "${OUTPUT_WIDTH}x${OUTPUT_HEIGHT}" \
      -f hls \
      -hls_time "${HLS_TIME}" \
      -hls_list_size "${HLS_LIST_SIZE}" \
      -hls_flags delete_segments \
      -t "${CHECK_INTERVAL}" \
      /output/mosaic/index.m3u8
    return

  elif [ "$count" -eq 3 ]; then
    # 3 streams — 2x2 with black bottom-right
    echo "[mosaic] Layout: 2x2 (3 streams + black)"
    ffmpeg -re \
      -i "${active[0]}" \
      -i "${active[1]}" \
      -i "${active[2]}" \
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
      -t "${CHECK_INTERVAL}" \
      /output/mosaic/index.m3u8
    return

  else
    # 4 streams — full 2x2 mosaic
    echo "[mosaic] Layout: 2x2 (4 streams)"
    ffmpeg -re \
      -i "${active[0]}" \
      -i "${active[1]}" \
      -i "${active[2]}" \
      -i "${active[3]}" \
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
      -t "${CHECK_INTERVAL}" \
      /output/mosaic/index.m3u8
    return
  fi
}

# Main loop
while true; do
  run_mosaic
  echo "[mosaic] Cycle complete, rechecking streams in ${RETRY_DELAY}s..."
  sleep "${RETRY_DELAY}"
  RETRY_DELAY=$(( RETRY_DELAY * 2 ))
  if [ "${RETRY_DELAY}" -gt "${MAX_DELAY}" ]; then
    RETRY_DELAY="${MAX_DELAY}"
  fi
done