#!/bin/bash

nodesdir="$(dirname $0)/nodesets"

for file in `ls $nodesdir`;
do
    node=$(echo $file | sed -e 's/.yml//g');
    echo "Running test for $node";
    BEAKER_set=$node rake beaker;
done