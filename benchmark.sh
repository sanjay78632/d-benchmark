#!/bin/bash

# Step 1: Install Dependencies (only needed for local testing)
echo "Installing dependencies..."
sudo apt update && sudo apt install -y hyperfine time jq

# Step 2: Set Environment Variables
OLD_COMPILER="/home/sanjay/d_benchmark/dmd/generated/linux/release/64/dmd"
NEW_COMPILER="/home/sanjay/d_benchmark/dmd/generated/linux/release/64/dmd"
MODULE="/home/sanjay/d_benchmark/phobos/std/package.d"
PHOBOS_PATH="/home/sanjay/d_benchmark/phobos"

# Debug: Check if compiler exists
if [ ! -f "$OLD_COMPILER" ]; then
    echo "❌ ERROR: DMD compiler not found at $OLD_COMPILER"
    exit 1
fi

# Debug: Check if Phobos exists
if [ ! -d "$PHOBOS_PATH/std" ]; then
    echo "❌ ERROR: Phobos source directory not found at $PHOBOS_PATH/std"
    exit 1
fi

echo "✅ DMD and Phobos found. Running benchmarks..."

# Step 3: Run Benchmark (Compare Old and New Compiler)
hyperfine --warmup 2 --runs 5 --style basic --export-json benchmark_results.json \
    "$OLD_COMPILER -i=std -c $MODULE" \
    "$NEW_COMPILER -i=std -c $MODULE" || exit 1

# Step 4: Extract Benchmark Data
if [ -f benchmark_results.json ]; then
    OLD_TIME=$(jq '.results[0].mean' benchmark_results.json)
    NEW_TIME=$(jq '.results[1].mean' benchmark_results.json)
else
    echo "❌ ERROR: Benchmark results not found!"
    exit 1
fi

# Step 5: Measure RAM Usage
RAM_USAGE_OLD=$( /usr/bin/time -v $OLD_COMPILER -i=std -c $MODULE 2>&1 | grep 'Maximum resident set size' | awk '{print $6}')
RAM_USAGE_NEW=$( /usr/bin/time -v $NEW_COMPILER -i=std -c $MODULE 2>&1 | grep 'Maximum resident set size' | awk '{print $6}')

# Step 6: Save Results
echo "Old Compile Time: $OLD_TIME sec" > results.txt
echo "New Compile Time: $NEW_TIME sec" >> results.txt
echo "Old RAM Usage: $RAM_USAGE_OLD KB" >> results.txt
echo "New RAM Usage: $RAM_USAGE_NEW KB" >> results.txt

# Step 7: Print Results
cat results.txt
echo "✅ Benchmark completed successfully. Exiting..."
exit 0

