#!/bin/bash

startdir=$(pwd)
rootdir=$(dirname $0)
nodesdir="${rootdir}/nodesets"
logdir="${rootdir}/logs"

for file in `ls $nodesdir`;
do
    node=$(echo $file | sed -e 's/.yml//g')
    mkdir -p ${logdir}/${node}
    logfile="${logdir}/${node}/dispatcher.log"

    echo "Running test dispatcher_spec for ${node}"
    BEAKER_set=${node} bundle exec rspec spec/acceptance/dispatcher_acceptance_spec.rb > ${logfile} 2>&1
done