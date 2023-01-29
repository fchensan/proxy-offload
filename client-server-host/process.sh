#!/bin/bash
# NOTE : Quote it else use array to avoid problems #
FILES="./data/*"
for f in $FILES
do
  echo "Processing $f file..."
  NAME=$(basename $f)
  ./dpbench/tools/clients/h1load/source/scripts/relative-time.sh $f > data-normalized/$NAME-normalized.dat
done
cp data-normalized/* graphs/
FILES="./graphs/*"
for f in $FILES
do
  echo "Graphing $f file..."
  NAME=$(basename $f)
  ./dpbench/tools/reporting/gnuplot/graph-h1load-rps-lat-ref-con_split.sh $f
done
rm graphs/*.dat
