#!/bin/bash

RESULTS_1="dse_a1_part1_out/results_a1_p1.csv"
RESULTS_2="dse_a1_part2_out/results_a1_p2.csv"
RESULTS_3="dse_a1_part3_out/results_a1_p3.csv"
SYS_CONF="system.cfg"

FINAL_CFG_PATH="submit_cfgs_a1/"
mkdir -p "$FINAL_CFG_PATH"
TOP_TEN="$FINAL_CFG_PATH/top_ten_conf.csv"
echo "Rank,ArrayHeight,ArrayWidth,IfmapSram,FilterSram,OfmapSram,Dataflow,Score" > "$TOP_TEN"


COMB_RESULTS="$FINAL_CFG_PATH/combined_results.csv"
awk 'FNR==1 && NR!=1 {next} {print}' dse_a1_part1_out/results_a1_p1.csv dse_a1_part2_out/results_a1_p2.csv dse_a1_part3_out/results_a1_p3.csv > "$COMB_RESULTS"

declare -a RESULTS_ARR
while IFS=',' read -r score height width ifmap filter ofmap dataflow cfg subdir; do
    RESULTS_ARR+=("$score,$height,$width,$ifmap,$filter,$ofmap,$dataflow,$cfg,$subdir")
done < "$COMB_RESULTS"

IFS=$'\n' sorted=($(sort -t',' -k1,1nr <<< "${RESULTS_ARR[*]}"))
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

        FINAL_CFG_PATH="submit_cfgs_a1/"
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
