#!/bin/bash

nodesdir="$(dirname $0)/nodesets"

for file in `ls $nodesdir`;
do
    node=$(echo $file | sed -e 's/.yml//g');
    echo "Running test $1 for $node";
    BEAKER_set=$node bundle exec rspec $1;
done