#!/bin/bash
# Oracle DB performance monitor with oratop (logs only errors)

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

# Config
source /home/oracle/.bash_profile
ORATOP_DIR="/home/oracle/oratop-history"
LOG_DIR="$ORATOP_DIR/logs"
RETENTION_HOURS=24
INTERVAL_SECONDS=5
ITERATIONS=720  # 720 x 5s = 1 hour

# Check if 7za exists
if ! command -v 7za &>/dev/null; then
    echo "$(date) - ERROR: 7za not installed. Run: sudo yum install p7zip" >> "$ORATOP_DIR/oratop.log"
    exit 1
fi

mkdir -p "$ORATOP_DIR" "$LOG_DIR"

# Compress files + handle errors
cleanup_old_files() {
    # Compress latest oratop output
    latest_file=$(ls -t "$ORATOP_DIR"/oratop-*.out 2>/dev/null | head -n1)
    if [ -n "$latest_file" ]; then
        if ! 7za a -tzip "${latest_file}.zip" "$latest_file" &>/dev/null; then
            echo "$(date) - ERROR: Failed to compress $latest_file" >> "$ORATOP_DIR/oratop.log"
        else
            rm -f "$latest_file"
            mv "${latest_file}.zip" "$LOG_DIR/"
        fi
    fi

    # Clean old files (silent unless error)
    if ! find "$LOG_DIR" -name "*.zip" -mtime +1 -exec rm -f {} \; &>/dev/null; then
        echo "$(date) - ERROR: Failed to delete old files" >> "$ORATOP_DIR/oratop.log"
    fi
}

# Main loop (no success logs)
while true; do
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    OUTPUT_FILE="$ORATOP_DIR/oratop-$TIMESTAMP.out"

    # Run oratop (log only if fails)
    if ! $ORACLE_HOME/suptools/oratop/oratop -bfrsi$INTERVAL_SECONDS -n $ITERATIONS -o "$OUTPUT_FILE" / AS SYSDBA; then
        echo "$(date) - ERROR: oratop failed to run" >> "$ORATOP_DIR/oratop.log"
    fi

    cleanup_old_files
done
