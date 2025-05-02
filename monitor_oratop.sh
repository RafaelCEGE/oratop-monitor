#!/bin/bash
# Oracle DB performance monitor with oratop (interactive config + validation + stop option)

# STOP OPTION
if [[ "$1" == "stop" ]]; then
    echo "🔍 Checking for running oratop processes..."
    ps -ef | grep '[o]ratop' | grep -v grep

    echo "⚠️  Do you want to kill these processes? (y/n): "
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        pkill -f oratop && echo "✅ oratop processes terminated."
    else
        echo "❌ No action taken. Exiting."
    fi
    exit 0
fi


source /home/oracle/.bash_profile
ORATOP_DIR="/home/oracle/oratop-history"
LOG_DIR="$ORATOP_DIR/logs"
CONFIG_FILE="$ORATOP_DIR/oratop.config"
LOG_FILE="$ORATOP_DIR/oratop.log"

clear
echo "======================================"
echo ""
echo "     ___           _                          "
echo "    /___\\_ __ __ _| |_ ___  _ __              "
echo "   //  // '__/ _\` | __/ _ \\| '_ \            "
echo "  / \\_//| | | (_| | || (_) | |_) |           "
echo "  \\___/ |_|  \\__,_|\\__\\___/| .__/            "
echo "                            |_|              "
echo ""
echo "    Oracle DB Performance Monitor      "
echo "    Developed by Pablo Travesso      "
echo "======================================"

mkdir -p "$ORATOP_DIR" "$LOG_DIR"

is_non_negative_integer() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

is_valid_retention_format() {
    [[ "$1" =~ ^[0-9]+[[:space:]]*(minutes|minute|hours|hour|days|day)$ ]]
}

if [[ -f "$CONFIG_FILE" ]]; then
    echo ""
    echo "A previous configuration was found:"
    cat "$CONFIG_FILE"
    echo ""
    read -p "Do you want to keep this configuration? (y/n): " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        rm -f "$CONFIG_FILE"
    fi
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo ""
    echo "🔧 Configuring oratop monitor..."

    while true; do
        read -p "Retention before compressing .out (e.g. 90 minutes / 2 hours): " RETENTION_INPUT
        if [[ "$RETENTION_INPUT" =~ ^([0-9]+)[[:space:]]*(minutes|minute|hours|hour)$ ]]; then
            VALUE="${BASH_REMATCH[1]}"
            UNIT="${BASH_REMATCH[2]}"
            [[ "$UNIT" =~ minutes|minute ]] && RETENTION_SECONDS=$((VALUE * 60))
            [[ "$UNIT" =~ hours|hour ]] && RETENTION_SECONDS=$((VALUE * 3600))
            break
        else
            echo "❌ Please enter format like: 90 minutes / 2 hours."
        fi
    done

    while true; do
        read -p "Retention for compressed logs (e.g. 2 days, 12 hours, 90 minutes): " RETENTION_FILE
        is_valid_retention_format "$RETENTION_FILE" && break
        echo "❌ Invalid format. Try again."
    done

    while true; do
        read -p "Seconds between each data collection? (e.g. 5): " INTERVAL_SECONDS
        is_non_negative_integer "$INTERVAL_SECONDS" && (( INTERVAL_SECONDS > 0 )) && break
        echo "❌ Invalid input."
    done

    while true; do
        read -p "For how long should each output file run? (e.g. 60 minutes / 2 hours): " DURATION_INPUT
        if [[ "$DURATION_INPUT" =~ ^([0-9]+)[[:space:]]*(minutes|minute|hours|hour)$ ]]; then
            DURATION_VALUE="${BASH_REMATCH[1]}"
            DURATION_UNIT="${BASH_REMATCH[2]}"
            [[ "$DURATION_UNIT" =~ minutes|minute ]] && DURATION_SECONDS=$((DURATION_VALUE * 60))
            [[ "$DURATION_UNIT" =~ hours|hour ]] && DURATION_SECONDS=$((DURATION_VALUE * 3600))
            break
        else
            echo "❌ Please enter format like: 60 minutes / 2 hours."
        fi
    done

    if (( RETENTION_SECONDS > 0 && DURATION_SECONDS > RETENTION_SECONDS )); then
        echo "❌ Output duration cannot exceed retention time."
        exit 1
    fi

    ITERATIONS=$(( DURATION_SECONDS / INTERVAL_SECONDS ))

    if (( ITERATIONS < 1 )); then
        echo "❌ The duration is too short or the interval is too long. Number of iterations would be zero."
        echo "   Please ensure that duration is greater than interval."
        exit 1
    fi

    echo "RETENTION_SECONDS=$RETENTION_SECONDS" > "$CONFIG_FILE"
    echo "RETENTION_FILE=\"$RETENTION_FILE\"" >> "$CONFIG_FILE"
    echo "INTERVAL_SECONDS=$INTERVAL_SECONDS" >> "$CONFIG_FILE"
    echo "DURATION_SECONDS=$DURATION_SECONDS" >> "$CONFIG_FILE"
    echo "ITERATIONS=$ITERATIONS" >> "$CONFIG_FILE"
    echo "✅ Configuration saved."

    echo ""
    echo "========= Configuration Summary ========="
    echo "• Data will be collected every $INTERVAL_SECONDS seconds."
    echo "• Each output file will run for $DURATION_VALUE $DURATION_UNIT (total $DURATION_SECONDS seconds, $ITERATIONS iterations)."
    echo "• .out files will be compressed after $RETENTION_INPUT."
    echo "• Compressed .zip files will be kept for $RETENTION_FILE."
    echo "• Output .out files are stored in: $ORATOP_DIR"
    echo "• Compressed .zip files are stored in: $LOG_DIR"
    echo "• Log file for this script: $LOG_FILE"
    echo "========================================="
    echo ""
fi

source "$CONFIG_FILE"

echo "📈 Starting oratop monitoring loop..."
echo "Press Ctrl+C or run './$(basename "$0") stop' to terminate."

# Compress and cleanup function
cleanup_old_files() {
    echo "$(date) - Checking files for cleanup..." >> "$LOG_FILE"

    # Only compress if retention is set (>0)
    if (( RETENTION_SECONDS > 0 )); then
        now=$(date +%s)
        cutoff=$((now - RETENTION_SECONDS))

        find "$ORATOP_DIR" -maxdepth 1 -name "oratop-*.out" -type f | while read -r file; do
            mod_time=$(stat -c %Y "$file")
            if (( mod_time < cutoff )); then
                zip_file="${file}.zip"

                if [ ! -f "$zip_file" ]; then
                    echo "$(date) - Compressing $file..." >> "$LOG_FILE"

                    if 7za a -tzip "$zip_file" "$file" &>> "$LOG_FILE"; then
                        rm -f "$file"
                        mv "$zip_file" "$LOG_DIR/"
                        echo "$(date) - Compressed and moved $file to $LOG_DIR" >> "$LOG_FILE"
                    else
                        echo "$(date) - ERROR: Compression failed for $file" >> "$LOG_FILE"
                    fi
                fi
            fi
        done
    fi

    # Remove old .zip files from LOG_DIR based on RETENTION_FILE (e.g., "2 days", "12 hours")
    if ! find "$LOG_DIR" -name "*.zip" -type f ! -newermt "$(date -d "-$RETENTION_FILE" '+%Y-%m-%d %H:%M:%S')" -exec rm -f {} \; &>> "$LOG_FILE"; then
        echo "$(date) - ERROR: Failed to delete old .zip files using RETENTION_FILE=$RETENTION_FILE" >> "$LOG_FILE"
    else
        echo "$(date) - Old compressed logs cleaned up based on retention: $RETENTION_FILE" >> "$LOG_FILE"
    fi
}

while true; do
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    OUT_FILE="$ORATOP_DIR/oratop-${TIMESTAMP}.out"

    echo "📊 Running oratop -i $INTERVAL_SECONDS -n $ITERATIONS..."
    
    if ! "$ORACLE_HOME/suptools/oratop/oratop" -bfrsi"$INTERVAL_SECONDS" -n "$ITERATIONS" -o "$OUT_FILE" / AS SYSDBA > /dev/null 2>&1; then
        echo "$(date) - ERROR: oratop failed to run" >> "$LOG_FILE"
    else
        echo "$(date) - ✅ Output saved to $OUT_FILE" >> "$LOG_FILE"
    fi

    cleanup_old_files > /dev/null 2>&1
done

