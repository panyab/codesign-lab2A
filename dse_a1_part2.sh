#!/bin/bash

# param ranges
ARRAY_HEIGHT=(10)
ARRAY_WIDTH=(8 9 10)
IFMAP_SRAM=(4)
FILTER_SRAM=(4)
OFMAP_SRAM=(4)
DATAFLOW=("os")

# files and dirs
OUTPUT_DIR="dse_a1_part2_out"
SYSTEM_CFG="system_a1_p2.cfg"

# create output dir
mkdir -p "$OUTPUT_DIR"

CSV_FILE="$OUTPUT_DIR/results_a1_p2.csv"
echo "Score,ArrayHeight,ArrayWidth,IfmapSram,FilterSram,OfmapSram,Dataflow,CFGPath,SubdirPath" > "$CSV_FILE"

# method that writes to system.cfg
modify_sys_conf() {
    local new_cfg=$1 height=$2 width=$3 ifmap_sram=$4 filter_sram=$5 ofmap_sram=$6 dataflow=$7

    cp "$SYSTEM_CFG" "$new_cfg"

    sed -i \
    -e "s/^ArrayHeight.*/ArrayHeight : $height/" \
    -e "s/^ArrayWidth.*/ArrayWidth : $width/" \
    -e "s/^IfmapSramSzkB.*/IfmapSramSzkB: $ifmap_sram/" \
    -e "s/^FilterSramSzkB.*/FilterSramSzkB: $filter_sram/" \
    -e "s/^OfmapSramSzkB.*/OfmapSramSzkB: $ofmap_sram/" \
    -e "s/^Dataflow.*/Dataflow : $dataflow/" \
    "$new_cfg"
}


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

                            AVG_MAP_EFF_CONV=$(awk -F',' 'NR > 1 {sum += $5} END {print sum}' "$CSV_FILE_CONV")
                            AVG_MAP_EFF_GEMM=$(awk -F',' 'NR > 1 {sum += $5} END {print sum}' "$CSV_FILE_GEMM")
                            AVG_MAP_EFF=$(echo "scale=12; ($AVG_MAP_EFF_CONV + $AVG_MAP_EFF_GEMM)/5" | bc -l)
                            echo "$AVG_MAP_EFF"
                            if (( $(echo "$AVG_MAP_EFF < 90" | bc -l) )); then
                                ((index++))
                                continue
                            fi

                            SCORE=$(echo "scale=12; (80000 / $TOTAL_CYCLES) + ($AVG_MAP_EFF * 8)" | bc -l )
                            RES+=("$SCORE,$height,$width,$ifmap,$filter,$ofmap,$dataflow,$CFG,$SUBDIR")
                            echo "$SCORE,$height,$width,$ifmap,$filter,$ofmap,$dataflow,$CFG,$SUBDIR" >> "$CSV_FILE"

                        fi

                        ((index++))
                    done
                done
            done
        done
    done
done

# CSV_FILE="$OUTPUT_DIR/results_a1_p2.csv"
# echo "Score,ArrayHeight,ArrayWidth,IfmapSram,FilterSram,OfmapSram,Dataflow,CFGPath,SubdirPath" > "$CSV_FILE"
# for result in "${RES[@]}"; do
#     echo "$result" >> "$CSV_FILE"
# done

IFS=$'\n' sorted=($(sort -t',' -k1,1nr <<< "${RES[*]}"))
unset IFS

SORTED_CSV_FILE="$OUTPUT_DIR/sorted_a1_p2.csv"
echo "Score,ArrayHeight,ArrayWidth,IfmapSram,FilterSram,OfmapSram,Dataflow,CFGPath,SubdirPath" > "$SORTED_CSV_FILE"
for entry in "${sorted[@]}"; do 
    echo "$entry" >> "$SORTED_CSV_FILE"
done