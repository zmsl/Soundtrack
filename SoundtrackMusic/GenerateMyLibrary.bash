#!/bin/bash

function debug() {
  if [ -n "$DEBUG" ] && [ "$DEBUG" -ne 0 ]
  then
    echo "$1"
  fi
}

function error() {
  >&2 echo "$1"
}

function hex_str_to_int() {
  printf "%d" 0x"$1"
}

#------------ ID3 Parsing ----------------

#Shell script to read ID3v1.x Tag from an mp3 audio file
#Known Issue: Because the '\0' are replaced with ' ' blankspaces. The Genre value 0 will be replaced by 32
#To get it right instead of storing the tag string in a variable direct access is needed

# ID3v2 constants
tag_header_size_characters=20
frame_header_size_characters=20

function print_id3v2_version() {
  id3=$1
  #debug "ID3 Header: $id3"
  id3v2_ver=${id3:6:2}
  id3v2_ver=$(hex_str_to_int "$id3v2_ver")

  id3v2_rev=${id3:8:2}
  id3v2_rev=$(hex_str_to_int "$id3v2_rev")
  #debug "ID3v2.$id3v2_ver.$id3v2_rev Tag present"
}

shifted_size=0
function read_and_shift_tag_byte() {
  id3=$1
  shift_amount=$2
  character_read_start=$3
  character_read_end=$((character_read_start+1))
  size=$(echo "$id3" | cut -c"$character_read_start"-$character_read_end)
  #debug "Before decode value: $size"
  size=$(hex_str_to_int "$size")
  #debug "Decimal size before bit shift: $size"
  size=$((size<<shift_amount))
  #debug "Decimal size after bit shift: $size"
  shifted_size=$size
}

id3v2_size=0
function parse_id3v2_tag_size() {
  id3=$1
  read_and_shift_tag_byte $id3 21 13
  id3v2_size_1=$shifted_size
  read_and_shift_tag_byte $id3 14 15
  id3v2_size_2=$shifted_size
  read_and_shift_tag_byte $id3 7 17
  id3v2_size_3=$shifted_size
  read_and_shift_tag_byte $id3 0 19
  id3v2_size_4=$shifted_size
  id3v2_size=$(($id3v2_size_1+$id3v2_size_2+$id3v2_size_3+$id3v2_size_4))
  id3v2_size_characters=$(($id3v2_size*2))

  #debug "Total tag size: $id3v2_size"
}

function parse_id3v2 {
    while [ -n "$1" ]
     do

      file="$1"

      if [ ! -f "$file" ]
      then
        error "File \"$file\" does not exist"
        shift 1
        continue
      fi

      tag=$(tail -c128 "$file" | tr '\0' ' ' 2>/dev/null) # Replace NULL with spaces
      id3=$(head -c10 "$file" | tr '\0' ' ' 2>/dev/null) # NULLs are being omitted

      id3v1_sig=${tag0:3}
      id3v2_sig=${id3:0:3}

      if [ "$id3v1_sig" = "TAG" ]
      then
          debug "ID3v1.x Tag present"
      fi

      xxd -p "$file" | tr -d '\n' > .hexdumptmp 2>/dev/null
      if [ "$id3v2_sig" = "ID3" ]
      then
        id3=$(head -c$tag_header_size_characters .hexdumptmp)
        print_id3v2_version "$id3"
        parse_id3v2_tag_size "$id3"

        i=$frame_header_size_characters
        while [ $i -lt $id3v2_size_characters ]
        do
          frame_header_end_index=$((i+frame_header_size_characters))
          #debug "Getting header bytes from $i to $frame_header_end_index"

          frame_header_bytes=$(dd if=".hexdumptmp" bs=1 skip=$i count=$frame_header_size_characters 2>/dev/null)
          #debug "Frame header bytes: $frame_header_bytes"

          frame_id=$(echo "${frame_header_bytes:0:8}" | xxd -r -p | tr -d '\0' 2>/dev/null)
          #debug "Frame Id: $frame_id"

          frame_size=${frame_header_bytes:8:8}
          #debug "Frame size bytes: $frame_size"
          frame_size=$(hex_str_to_int "$frame_size")
          #debug "Frame Size: $frame_size"
          frame_size_characters=$((frame_size*2))

          if [ -z "$frame_id" ] || [ "$frame_size" -eq 0 ]
          then
            debug "Bailing early from $file, invalid frame id or frame size."
            break
          fi

          if [[ $frame_id == T* ]]
          then
            frame_body_bytes=$(dd if=".hexdumptmp" bs=1 skip="$frame_header_end_index" count=$frame_size_characters 2>/dev/null)
            frame_body_text=$(echo "$frame_body_bytes" | xxd -r -p | tr -d '\0' 2>/dev/null)
            #debug "Frame body text: $frame_body_text"

            echo "$frame_id" "$frame_body_text"

            if [ "$frame_id" == "TIT2" ] && [ "$BAIL_AFTER_TITLE" == "1" ]; then
              exit 0
            fi
          fi

          i=$((i+frame_header_size_characters+frame_size_characters))
        done
      elif [ "$id3v1_sig" = "TAG" ]
      then
          song_name=${tag:3:30}
          artist=${tag:33:30}
          album=${tag:63:30}
          year=${tag:93:4}
          comment=${tag:97:28}
          #The second last byte of the Comment field ie the 126th byte of the tag is always zero in ID3v1.1
          album_track=${tag:126:1} #Last two bytes of comment field was reserved for album track no. in ID3v1.1
          album_track=$(hex_str_to_int "'$album_track") #Convert Album Track ASCII to value
          genre=${tag:127:1}
          genre=$(hex_str_to_int "'$genre") #Convert Genre to ASCII value

          #Reads the genre string from the file id3v1_genre_string
          if [ -f id3v1_genre_list ]
          then
            genre_string=$(grep "\<$genre\>" id3v1_genre_list)
          else
            genre_string="Genre Code = $genre"
          fi


          echo -e "Displaying ID3v1 Tag of file \"$file\"\n"
          echo "Song Name   : $song_name"
          echo "Artist      : $artist"
          echo "Album       : $album"
          echo "Year        : $year"
          echo "Comment     : $comment"
          echo "Album Track : $album_track"
          echo "Genre       : $genre_string"

        else
        echo "The file \"$file\" does not contain an ID3v1 tag"
      fi

    shift 1
    done
}

# -------------------- MP3 Header parsing -------------------

function get_next_header_index() {
    if [ "$potential_headers_array_length" -gt 5000 ]; then
        potential_header_index=$(($potential_header_index + 50))
    elif [ "$potential_headers_array_length" -gt 1000 ]; then
        potential_header_index=$(($potential_header_index + 10))
    else
        potential_header_index=$(($potential_header_index + 1))
    fi

    echo $potential_header_index
}

# Form of (layer) as arg 1
function padding_map() {
  if [ "$1" -eq 0 ]; then
    echo 0
  else
    case $2 in
    '1') echo 4 ;;
    '2') echo 1 ;;
    '3') echo 1 ;;
    esac
  fi
}

function mpeg_version_map() {
  case $1 in
  '0') echo 3 ;; # MPEG 2.5
    # 1 is reserved
  '2') echo 2 ;; # MPEG 2
  '3') echo 1 ;; # MPEG 1
  esac
}

function layer_map() {
  case $1 in
  # 0 is reserved
  '1') echo 3 ;; # Layer III
  '2') echo 2 ;; # Layer II
  '3') echo 1 ;; # Layer I
  esac
}

# Constants for sampling rate lookup
# Form of  (sampling_rate_index)_(mpeg_version)
# for simplicity mpeg 2.5 is 3 in the map
function sampling_rate_map() {
  case $1 in
  '0_1') echo 44100 ;; # index 0 mpeg 1
  '0_2') echo 22050 ;; # index 0 mpeg 2
  '0_3') echo 11025 ;; # index 0 mpeg 2.5

  '1_1') echo 48000 ;; # index 1 mpeg 1
  '1_2') echo 24000 ;; # index 1 mpeg 2
  '1_3') echo 12000 ;; # index 1 mpeg 2.5

  '2_1') echo 32000 ;; # index 2 mpeg 1
  '2_2') echo 16000 ;; # index 2 mpeg 2
  '2_3') echo 8000 ;;  # index 2 mpeg 2.5
  esac
}

#           MPEG1	MPEG2	MPEG2.5
# Layer I	  384	  384 	384
# Layer II	1152 	1152	1152
# Layer III 1152 	576 	576
# Form of (mpeg_version)_(layer)
# for simplicity mpeg 2.5 is 3 in the map
function samples_per_frame_map() {
  case $1 in
  '1_1') echo 384 ;;
  '1_2') echo 1152 ;;
  '1_3') echo 1152 ;;

  '2_1') echo 384 ;;
  '2_2') echo 1152 ;;
  '2_3') echo 576 ;;

  '3_1') echo 384 ;;
  '3_2') echo 1152 ;;
  '3_3') echo 576 ;;
  esac
}

# Constants for bit rate lookup
# Form of  (bit_rate_index)_(mpeg_version)_(layer)
# for simplicity mpeg 2.5 is 3 in the map
function bit_rate_map() {
  case $1 in
  '1_1_1') echo 32 ;;
  '1_1_2') echo 32 ;;
  '1_1_3') echo 32 ;;
  '1_2_1') echo 32 ;;
  '1_2_2') echo 8 ;;
  '1_2_3') echo 8 ;;
  '1_3_1') echo 32 ;;
  '1_3_2') echo 8 ;;
  '1_3_3') echo 8 ;;

  '2_1_1') echo 64 ;;
  '2_1_2') echo 48 ;;
  '2_1_3') echo 40 ;;
  '2_2_1') echo 48 ;;
  '2_2_2') echo 16 ;;
  '2_2_3') echo 16 ;;
  '2_3_1') echo 48 ;;
  '2_3_2') echo 16 ;;
  '2_3_3') echo 16 ;;

  '3_1_1') echo 96 ;;
  '3_1_2') echo 56 ;;
  '3_1_3') echo 48 ;;
  '3_2_1') echo 56 ;;
  '3_2_2') echo 24 ;;
  '3_2_3') echo 24 ;;
  '3_3_1') echo 56 ;;
  '3_3_2') echo 24 ;;
  '3_3_3') echo 24 ;;

  '4_1_1') echo 128 ;;
  '4_1_2') echo 64 ;;
  '4_1_3') echo 56 ;;
  '4_2_1') echo 64 ;;
  '4_2_2') echo 32 ;;
  '4_2_3') echo 32 ;;
  '4_3_1') echo 64 ;;
  '4_3_2') echo 63 ;;
  '4_3_3') echo 32 ;;

  '5_1_1') echo 160 ;;
  '5_1_2') echo 80 ;;
  '5_1_3') echo 64 ;;
  '5_2_1') echo 80 ;;
  '5_2_2') echo 40 ;;
  '5_2_3') echo 40 ;;
  '5_3_1') echo 80 ;;
  '5_3_2') echo 40 ;;
  '5_3_3') echo 40 ;;

  '6_1_1') echo 192 ;;
  '6_1_2') echo 96 ;;
  '6_1_3') echo 80 ;;
  '6_2_1') echo 96 ;;
  '6_2_2') echo 48 ;;
  '6_2_3') echo 48 ;;
  '6_3_1') echo 96 ;;
  '6_3_2') echo 48 ;;
  '6_3_3') echo 48 ;;

  '7_1_1') echo 224 ;;
  '7_1_2') echo 112 ;;
  '7_1_3') echo 96 ;;
  '7_2_1') echo 112 ;;
  '7_2_2') echo 56 ;;
  '7_2_3') echo 56 ;;
  '7_3_1') echo 112 ;;
  '7_3_2') echo 56 ;;
  '7_3_3') echo 56 ;;

  '8_1_1') echo 256 ;;
  '8_1_2') echo 128 ;;
  '8_1_3') echo 112 ;;
  '8_2_1') echo 128 ;;
  '8_2_2') echo 64 ;;
  '8_2_3') echo 64 ;;
  '8_3_1') echo 128 ;;
  '8_3_2') echo 64 ;;
  '8_3_3') echo 64 ;;

  '9_1_1') echo 288 ;;
  '9_1_2') echo 160 ;;
  '9_1_3') echo 128 ;;
  '9_2_1') echo 144 ;;
  '9_2_2') echo 80 ;;
  '9_2_3') echo 80 ;;
  '9_3_1') echo 144 ;;
  '9_3_2') echo 80 ;;
  '9_3_3') echo 80 ;;

  '10_1_1') echo 320 ;;
  '10_1_2') echo 192 ;;
  '10_1_3') echo 160 ;;
  '10_2_1') echo 160 ;;
  '10_2_2') echo 96 ;;
  '10_2_3') echo 96 ;;
  '10_3_1') echo 160 ;;
  '10_3_2') echo 96 ;;
  '10_3_3') echo 96 ;;

  '11_1_1') echo 352 ;;
  '11_1_2') echo 224 ;;
  '11_1_3') echo 192 ;;
  '11_2_1') echo 176 ;;
  '11_2_2') echo 112 ;;
  '11_2_3') echo 112 ;;
  '11_3_1') echo 176 ;;
  '11_3_2') echo 112 ;;
  '11_3_3') echo 112 ;;

  '12_1_1') echo 384 ;;
  '12_1_2') echo 256 ;;
  '12_1_3') echo 224 ;;
  '12_2_1') echo 192 ;;
  '12_2_2') echo 128 ;;
  '12_2_3') echo 128 ;;
  '12_3_1') echo 192 ;;
  '12_3_2') echo 128 ;;
  '12_3_3') echo 128 ;;

  '13_1_1') echo 416 ;;
  '13_1_2') echo 320 ;;
  '13_1_3') echo 256 ;;
  '13_2_1') echo 224 ;;
  '13_2_2') echo 144 ;;
  '13_2_3') echo 144 ;;
  '13_3_1') echo 224 ;;
  '13_3_2') echo 144 ;;
  '13_3_3') echo 144 ;;

  '14_1_1') echo 448 ;;
  '14_1_2') echo 384 ;;
  '14_1_3') echo 320 ;;
  '14_2_1') echo 256 ;;
  '14_2_2') echo 160 ;;
  '14_2_3') echo 160 ;;
  '14_3_1') echo 256 ;;
  '14_3_2') echo 160 ;;
  '14_3_3') echo 160 ;;
  esac
}

function parse_mp3_duration {
    file=$1

    if [ ! -f "$file" ]; then
      error "File \"$file\" does not exist"
      exit 1
    fi

    valid_frames_to_count=$2
    if [ -z "$valid_frames_to_count" ]; then
      error "Provide frames to count as the 2nd argument"
      exit 2
    fi

    # Constants
    frame_header_byte_size=4
    frame_header_size_characters=$((frame_header_byte_size * 2))

    if [ ! -z $3 ]; then
      echo "3rd arg provided so skipping xxd step"
    else
      xxd -p "$file" | tr -d '\n' > .hexdumptmp 2>/dev/null
    fi

    potential_mp3_frame_headers=($(perl -n0777e 'print pos()-length($&),"\n" while /fffa|fffb|fff3/g' .hexdumptmp))
    potential_headers_array_length=${#potential_mp3_frame_headers[@]}
    potential_header_index=0
    #debug "Potential headers length: $potential_headers_array_length"

    file_size_characters=$(wc -c <.hexdumptmp)
    #debug "File size in characters: $file_size_characters"

    first_frame_offset=0
    valid_frame_count=0
    kbit_rate_sum=0
    i=${potential_mp3_frame_headers[$potential_header_index]}
    while [ $potential_header_index -lt "$potential_headers_array_length" ] && [ "$i" -lt "$file_size_characters" ] && [ $valid_frame_count -lt "$valid_frames_to_count" ]; do
      #header_hex_address=$(printf "%08x" $((i / 2)))
      frame_header_hex=$(dd if=".hexdumptmp" bs=1 skip="$i" count=$frame_header_size_characters 2>/dev/null)

      sync_word=${frame_header_hex:0:3}

      if [[ $sync_word == fff ]]; then
        #debug "Found potential mp3 frame: $sync_word at character $i, address $header_hex_address"
        #debug "Potential Frame header: $frame_header_hex"

        # Hex character 3 represents: 3 bits for sync word, 1 bit for mpeg version (1/2 of the 2 bits for mpeg version)
        {
          hex_character_three=${frame_header_hex:2:1}
          character_three_int=$(hex_str_to_int "$hex_character_three")

          mpeg_version_bit_1=$((character_three_int & 2#0001))
        }

        # Hex character 4 represents: 1 bit for MPEG version, 2 bits for Layer index, 1 bit for protection
        {
          hex_character_four=${frame_header_hex:3:1}
          character_four_int=$(hex_str_to_int "$hex_character_four")

          mpeg_version_bit_2=$(((character_four_int & 2#1000) >> 3))
          mpeg_version_index=$(((mpeg_version_bit_1 << 1) + mpeg_version_bit_2))
          mpeg_version=$(mpeg_version_map $mpeg_version_index)

          layer_index=$(((character_four_int & 2#0110) >> 1))
          layer=$(layer_map $layer_index)

          protected_bit=$((character_four_int & 2#0001))

          #debug "  ($hex_character_four) MPEG version: $mpeg_version, Layer: $layer, Protected bit: $protected_bit"
        }

        # Hex character 5 represents: Bit rate index, need to lookup value into table of constants
        {
          hex_character_five=${frame_header_hex:4:1}
          character_five_int=$(hex_str_to_int "$hex_character_five")
          bit_rate_index=$character_five_int

          bit_rate_key="${bit_rate_index}_${mpeg_version}_${layer}"
          kbit_rate=$(bit_rate_map "$bit_rate_key")
          bit_rate=$((kbit_rate * 1000))

          if [ "$bit_rate_index" -eq 0 ]; then
            #debug "Got free format bit rate, assuming invalid header"
            potential_header_index=$(get_next_header_index)
            i=${potential_mp3_frame_headers[$potential_header_index]}
            continue
          fi

          #debug "  ($hex_character_five) Bit rate: (key = $bit_rate_key) $kbit_rate kb/s"
        }

        # Hex character 6 represents: 2 bits for sampling rate index, 1 bit for padding, 1 bit for private bit
        {
          hex_character_six=${frame_header_hex:5:1}
          character_six_int=$(hex_str_to_int "$hex_character_six")

          sampling_rate_index=$(((character_six_int & 2#1100) >> 2))
          sampling_rate_key="${sampling_rate_index}_${mpeg_version}"
          sampling_rate=$(sampling_rate_map "$sampling_rate_key")

          padding_bit=$(((character_six_int & 2#0010) >> 1))
          padding_amount_bytes=$(padding_map $padding_bit "$layer")

          private_bit=$((character_six_int & 2#0001))

          #debug "  ($hex_character_six) Sampling rate: (key = $sampling_rate_key) ${sampling_rate}Hz, Padding: $padding_bit, Padding amount bytes: $padding_amount_bytes, Private: $private_bit"
        }

        # Hex character 7 represents: 2 bits for channel mode, 2 bits for mode extension
        {
          hex_character_seven=${frame_header_hex:6:1}
          character_seven_int=$(hex_str_to_int "$hex_character_seven")

          channel_mode=$(((character_seven_int & 2#1100) >> 2))

          channel_mode_extension=$((character_seven_int & 2#0011))

          #debug "  ($hex_character_seven) Channel mode: $channel_mode, Channel mode extension: $channel_mode_extension"
        }

        # Hex character 8 represents: 1 bit for copyright, 1 bit for original, 2 bits for emphasis
        {
          hex_character_eight=${frame_header_hex:6:1}
          character_eight_int=$(hex_str_to_int "$hex_character_eight")

          copyright_bit=$(((character_eight_int & 2#1000) >> 3))

          original_bit=$(((character_eight_int & 2#0100) >> 2))

          emphasis=$((character_eight_int & 2#0011))

          #debug "  ($hex_character_eight) Copyright: $copyright_bit, Original: $original_bit, Emphasis: $emphasis"
      }

      samples_per_frame_key="${mpeg_version}_${layer}"
      samples_per_frame=$(samples_per_frame_map "$samples_per_frame_key")

        # All reserved values
        if [ $sampling_rate_index -eq 3 ] || [ "$bit_rate_index" -eq 15 ] || [ $mpeg_version_index -eq 1 ] || [ $layer_index -eq 0 ]; then
          potential_header_index=$(get_next_header_index)
          i=${potential_mp3_frame_headers[$potential_header_index]}
          #debug "Invalid frame header, moving to next position"
          #debug "" # newline
          continue
        fi

        # Frame Size = ( (Samples Per Frame / 8 * Bitrate) / Sampling Rate) + Padding Size
        #debug "" # newline
        #debug "  Samples per frame key: $samples_per_frame_key, Samples per frame: $samples_per_frame"
        #debug "  Frame size bytes = (($samples_per_frame / 8 * $bit_rate) / $sampling_rate) + $padding_amount_bytes))"
        frame_size_bytes=$((((samples_per_frame * bit_rate / 8) / sampling_rate) + padding_amount_bytes))
        #debug "  Frame size bytes: $frame_size_bytes"

        frame_size_characters=$((frame_size_bytes * 2))
        next_header_start=$((i + frame_size_characters))
        next_frame_header_end_index=$((next_header_start + frame_header_size_characters))
        #debug "  Next frame start character: $i + $frame_size_characters = $next_header_start"
        if [ $next_frame_header_end_index -lt "$file_size_characters" ]; then
          #next_frame_header_hex=$(head -c$next_frame_header_end_index .hexdumptmp | tail -c$frame_header_size_characters)
          next_frame_header_hex=$(dd if=".hexdumptmp" bs=1 skip=$next_header_start count=$frame_header_size_characters 2>/dev/null)
          next_sync_word=${next_frame_header_hex:0:3}

          #next_header_hex_address=$(printf "%08x" $(($next_header_start / 2)))
          #debug "  Next frame header: $next_frame_header_hex at $next_header_hex_address"
          #debug "  Next frame sync word: $next_sync_word"

          if [[ $next_sync_word == fff ]]; then
            #debug "  CONFIRMED: Next frame starts with sync word"
            i=$next_header_start

            if [ $valid_frame_count -eq 0 ]; then
              first_frame_offset=$i
            fi

            valid_frame_count=$((valid_frame_count + 1))
            kbit_rate_sum=$((kbit_rate_sum + kbit_rate))
          else
            potential_header_index=$(get_next_header_index)
            i=${potential_mp3_frame_headers[$potential_header_index]}
            #debug "Sync word of next frame not valid, moving to next position, $i"
            #debug "" # newline
          fi
        fi
      else
        # Seek to the next byte boundary
        i=$((i + 2))
      fi
    done

    # Constant bit rate Duration = File Size / Bitrate * 8
    # Variable bit rate Duration = (Samples per frame * total frames) / sample rate
    average_bit_rate=$((kbit_rate_sum * 1000 / valid_frame_count))
    #debug "Average bit rate: $average_bit_rate b/s, first frame offset: $first_first_frame_offset, potential header index: $potential_header_index"

    file_size_bytes=$(((file_size_characters - first_frame_offset) / 2))
    duration=$((file_size_bytes * 8 / average_bit_rate))

    #debug "File size bytes: $file_size_bytes"
    echo "Duration $duration"
}

#---------- Generate Library --------------

cd "$(dirname "$0")" || exit 1

function parseTag {
  frame_text=$(echo "$1" | grep "$2"| tr -d "[:cntrl:]")
  if [ ! -z "$frame_text" ]
  then
    frame_text=${frame_text:5}
  else
    frame_text=$3
  fi

  echo $frame_text
}

function process_file {
  filePathWithExtension=$1
  echo -n "$(tput sc)Processing $1"

  relativeFilePath=${filePathWithExtension:2}
  relativeFolderPath=$(dirname "$relativeFilePath")
  fileNameNoExtension=$(basename "$filePathWithExtension" .mp3)
  relativeFilePathNoExtension="$relativeFolderPath/$fileNameNoExtension"

  tags=$(DEBUG=0 BAIL_AFTER_TITLE=1 parse_id3v2 "$filePathWithExtension")
  trackTitle=$(parseTag "$tags" "TIT2" "$fileNameNoExtension")
  album=$(parseTag "$tags" "TALB" "None")
  author=$(parseTag "$tags" "TPE1" "None")

  length=$(DEBUG=0 parse_mp3_duration "$filePathWithExtension" 25 1 | grep "Duration" | cut -c10-)

  echo "$(tput rc)$(tput el)$relativeFilePath: ${length}s, $trackTitle, $author, $album"

  addTrackStatement="    Soundtrack.Library.AddTrack(\"$relativeFilePathNoExtension\", $length, \"$trackTitle\", \"$author\", \"$album\")"
  addTrackStatement="${addTrackStatement//\.\//}"
  addTrackStatement="${addTrackStatement//\//\\\\}"
  echo "$addTrackStatement" >> MyTracks.lua
}

echo "-- This file is automatically generated" > MyTracks.lua
echo "-- Please do not edit it" >> MyTracks.lua

currentDate=$(date)
{
  echo "SMP3_PL_VERSION = \"$currentDate\"";
  echo "function Soundtrack_LoadMyTracks()";
  echo "   if SoundtrackAddon.db.profile.settings.MyTracksVersion == nil or SoundtrackAddon.db.profile.settings.MyTracksVersion ~= SMP3_PL_VERSION then";
  echo "      SoundtrackAddon.db.profile.settings.MyTracksVersion = SMP3_PL_VERSION";
  echo "      SoundtrackAddon.db.profile.settings.MyTracksVersionSame = false";
  echo "   else";
  echo "      SoundtrackAddon.db.profile.settings.MyTracksVersionSame = true";
  echo "   end";
} >> MyTracks.lua

FILES=$(find . -name \*.mp3)
while IFS= read -r file; do
    process_file "$file"
done <<< "$FILES"

echo "end" >> MyTracks.lua

echo "Generation complete!"

rm .hexdumptmp

