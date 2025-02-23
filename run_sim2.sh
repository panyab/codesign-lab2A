#!/bin/bash

# param ranges
ARRAY_HEIGHT=(3 4 5 6 7 8 9 10)
ARRAY_WIDTH=(3 4 5 6 7 8 9 10)
IFMAP_SRAM=(1 2 3 4)
FILTER_SRAM=(1 2 3 4)
OFMAP_SRAM=(1 2 3 4)
DATAFLOW=("ws" "os" "is")


# files and dirs
OUTPUT_DIR="outputA3"
SYSTEM_CFG="systemA3.cfg"
TOP_TEN="top_configs_a3.csv"

# create output dir
mkdir -p "$OUTPUT_DIR"

# method that writes to system.cfg
modify_sys_conf() {
    local new_cfg=$1 height=$2 width=$3 ifmap_sram=$4 filter_sram=$5 ofmap_sram=$6 dataflow=$7

    cp "$SYSTEM_CFG" "$new_cfg"

    sed -i '' \
    -e "s/^ArrayHeight.*/ArrayHeight : $height/" \
    -e "s/^ArrayWidth.*/ArrayWidth : $width/" \
    -e "s/^IfmapSramSzkB.*/IfmapSramSzkB: $ifmap_sram/" \
    -e "s/^FilterSramSzkB.*/FilterSramSzkB: $filter_sram/" \
    -e "s/^OfmapSramSzkB.*/OfmapSramSzkB: $ofmap_sram/" \
    -e "s/^Dataflow.*/Dataflow : $dataflow/" \
    "$new_cfg"
}

# init top 10 file 
echo "Rank,ArrayHeight,ArrayWidth,IfmapSram,FilterSram,OfmapSram,Dataflow,Score" > "$TOP_TEN"

declare -a RES
index=0

for height in "${ARRAY_HEIGHT[@]}"; do 
    for width in "${ARRAY_WIDTH[@]}"; do 
        for ifmap in "${IFMAP_SRAM[@]}"; do
            for filter in "${FILTER_SRAM[@]}"; do
                for ofmap in "${OFMAP_SRAM[@]}"; do
                    for dataflow in "${DATAFLOW[@]}"; do
                        CFG="$OUTPUT_DIR/config_${index}.cfg"
                        SUBDIR="$OUTPUT_DIR/run_${index}"
                        mkdir -p "$SUBDIR"

                        modify_sys_conf "$CFG" "$height" "$width" "$ifmap" "$filter" "$ofmap" "$dataflow"
                        
                        python3 scale-sim-v2/scalesim/scale.py -c "$CFG" -t lenet_conv.csv -p "$SUBDIR/conv"
                        python3 scale-sim-v2/scalesim/scale.py -c "$CFG" -t lenet_gemm.csv -i gemm -p "$SUBDIR/gemm"

                        CSV_FILE_CONV="$SUBDIR/conv/lenet_DSE_run/COMPUTE_REPORT.csv"
                        CSV_FILE_GEMM="$SUBDIR/gemm/lenet_DSE_run/COMPUTE_REPORT.csv"

                        if [[ -f "$CSV_FILE_CONV" && -f "$CSV_FILE_GEMM" ]]; then 
                            TOTAL_CYCLES_CONV=$(awk -F',' 'NR > 1 {sum += $2} END {print sum}' "$CSV_FILE_CONV")
                            TOTAL_CYCLES_GEMM=$(awk -F',' 'NR > 1 {sum += $2} END {print sum}' "$CSV_FILE_GEMM")
                            TOTAL_CYCLES=$(($TOTAL_CYCLES_CONV + $TOTAL_CYCLES_GEMM))

                            TOTAL_AREA=$(echo "scale=12; 525*($height * $width) + 1015.7*($ifmap + $filter)" | bc -l)

                            SCORE=$(echo "scale=12; (17500 / $TOTAL_CYCLES) + (15000 / $TOTAL_AREA)" | bc -l )
                            RES+=("$SCORE,$height,$width,$ifmap,$filter,$ofmap,$dataflow,$CFG,$SUBDIR")
                        fi

                        ((index++))
                    done
                done
            done
        done
    done
done

CSV_FILE="resultsA3.csv"
echo "Score,ArrayHeight,ArrayWidth,IfmapSram,FilterSram,OfmapSram,Dataflow,CFGPath,SubdirPath" > "$CSV_FILE"
for result in "${RES[@]}"; do
    echo "$result" >> "$CSV_FILE"
done

# sort and find top 10 

IFS=$'\n' sorted=($(sort -t',' -k1,1nr <<< "${RES[*]}"))
unset IFS

i=0
rank=0
for entry in "${sorted[@]}"; do 
    if (( $rank < 10 )); then
        IFS=',' read -r SCORE HEIGHT WIDTH IFMAP FILTER OFMAP DATAFLOW CFG SUBDIR <<< "$entry"

        if grep -q "$SCORE" "$TOP_TEN"; then
            ((i++))
            continue
        fi

        FINAL_CFG_PATH="submit_cfgsA3/"
        mkdir -p "$FINAL_CFG_PATH"
        SYSTEM_CFG="$FINAL_CFG_PATH/system${rank}.cfg"
        cp "$CFG" "$SYSTEM_CFG"
        MERGED_CSV="$FINAL_CFG_PATH/COMPUTE_REPORT${rank}.csv"
        echo "LayerID,Total Cycles,Stall Cycles,Overall Util %,Mapping Efficiency %,Compute Util %" > "$MERGED_CSV"
        awk 'NR>1' "$SUBDIR/conv/lenet_DSE_run/COMPUTE_REPORT.csv" >> "$MERGED_CSV"
        awk 'NR>1' "$SUBDIR/gemm/lenet_DSE_run/COMPUTE_REPORT.csv" >> "$MERGED_CSV"

        echo "$((rank+1)),$HEIGHT,$WIDTH,$IFMAP,$FILTER,$OFMAP,$DATAFLOW,$SCORE" >> "$TOP_TEN"
        ((i++))
        ((rank++))
    else
        break
    fi
done
