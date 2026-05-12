#!/bin/bash
# shebang line (bash use to interpret this script)

# $0 is Name of current Process
# NR: Number of Records, NR 1 is header
# cmd: User input
# $1 is positional parmeter (1st arg)

# Error message (Checking arg)
if [ $# -ne 1 ]; then
    echo "usage: $0 file"
    exit 1
fi

INPUT_FILE="$1"

# Whoami message
echo "************OSS1 - Project1************"
echo "*      StudentID : 12202522       *"
echo "*      Name : Minsang Choi        *"
echo "***************************************"
echo ""

# Menu loop until enter 6
while true; do
    echo ""
    echo "[MENU]"
    echo "1. Search tracks by artist name and track name"
    echo "2. List top 5 tracks by popularity in a specific genre"
    echo "3. Show top 5 longest tracks by duration"
    echo "4. Merge duplicate tracks and combine genres"
    echo "5. Analyze tracks - count, avg danceability, energy, valence"
    echo "6. Quit"
    read -p "Enter your COMMAND (1~6) : " cmd

    case "$cmd" in

        # 1. Search tracks by artist name and track name
        1)
            read -p "Enter an artist name to search: " artist_input
            read -p "Enter a track name to search: " track_input

            echo ""
            echo "Search results for \"${artist_input}\" / \"${track_input}\":"
            printf "%-30s %-40s %-10s %-10s\n" "artists" "track_name" "energy" "tempo"

            # "awk -v" is pass variable
            # .tsv file's field is divided by tab
            awk -F'\t' -v artist="$artist_input" -v track="$track_input" '
            BEGIN {
                a = tolower(artist)
                t = tolower(track)
            }
            NR > 1 {
                gsub(/\r/, "")
                if (tolower($2) == a && tolower($4) == t) {
                    printf "%-30s %-40s %-10s %-10s\n", $2, $4, $9, $18
                }
            }' "$INPUT_FILE"
            ;;

        # 2. List top 5 tracks by popularity in a specific genre
        2)
            read -p "Enter a genre: " genre_input

            echo ""
            echo "Top 5 tracks by popularity in \"${genre_input}\":"
            printf "%-30s %-40s %-15s %-10s %-10s\n" "artists" "track_name" "popularity" "energy" "valence"

            awk -F'\t' -v genre="$genre_input" '
            NR > 1 {
                gsub(/\r/, "")
                if (tolower($20) == tolower(genre)) {
                    printf "%s\t%s\t%s\t%s\t%s\n", $2, $4, $5, $9, $17
                }
            }' "$INPUT_FILE" | \
            sort -t$'\t' -k3 -nr | \
            awk -F'\t' '
            !seen[$1"\t"$2]++ {
                count++
                if (count <= 5)
                    printf "%-30s %-40s %-15s %-10s %-10s\n", $1, $2, $3, $4, $5
            }'
            ;;

        # 3. Show top 5 longest tracks by duration
        3)
            echo ""
            echo "Top 5 longest tracks by duration:"
            printf "%-30s %-45s %-10s\n" "artists" "track_name" "duration"

            awk -F'\t' '
            NR > 1 {
                gsub(/\r/, "")
                key = $2 "\t" $4
                if (!seen[key]++) {
                    print $6 "\t" $2 "\t" $4
                }
            }' "$INPUT_FILE" | \
            sort -t$'\t' -k1 -nr | \
            head -5 | \
            awk -F'\t' '{
                ms = $1 + 0
                total_sec = int(ms / 1000)
                mm = int(total_sec / 60)
                ss = total_sec % 60
                printf "%-30s %-45s %02d:%02d\n", $2, $3, mm, ss
            }'
            ;;

        # 4. Merge duplicate tracks and combine genres
        4)
            echo ""
            echo "Tracks appearing in multiple genres (top 5 by popularity):"
            printf "%-35s %-30s %-s\n" "track_name" "artists" "genres"

            awk -F'\t' '
            NR > 1 {
                gsub(/\r/, "")
                key = $2 "\t" $4
                if (!popularity[key]) popularity[key] = $5 + 0
                if (index(genres[key], $20) == 0) {
                    genres[key] = genres[key] ? genres[key] "|" $20 : $20
                    count[key]++
                }
            }
            END {
                for (key in count) {
                    if (count[key] >= 2) {
                        split(key, parts, "\t")
                        print popularity[key] "\t" parts[2] "\t" parts[1] "\t" genres[key]
                    }
                }
            }' "$INPUT_FILE" | \
            sort -t$'\t' -k1 -nr | \
            head -5 | \
            awk -F'\t' '{
                printf "%-35s %-30s %-s\n", $2, $3, $4
            }'
            ;;

        # 5. Analyze tracks - count, avg danceability, energy, valence
        5)
            read -p "Enter minimum popularity threshold: " threshold

            echo ""
            awk -F'\t' -v thresh="$threshold" '
            NR > 1 {
                gsub(/\r/, "")
                key = $2 "\t" $4
                if (!seen[key]++) {
                    val = $5 + 0
                    if (val >= thresh) {
                        count++
                        dance += $8
                        energy += $9
                        valence += $17
                    }
                }
            }
            END {
                if (count == 0) {
                    print "No tracks found with popularity >= " thresh
                } else {
                    printf "popularity >= %s tracks: %d\n", thresh, count
                    printf "avg danceability: %.2f\n", dance / count
                    printf "avg energy: %.2f\n", energy / count
                    printf "avg valence: %.2f\n", valence / count
                }
            }' "$INPUT_FILE"
            ;;

        # 6. Quit
        6)
            echo "Bye!"
            exit 0
            ;;

        *)
            echo "Invalid command. Please enter a number between 1 and 6."
            ;;
    esac

done
