#!/bin/bash

startdir=$(pwd)
rootdir=$(dirname $0)
nodesdir="${rootdir}/nodesets"
logdir="${rootdir}/log"

if [ "$1" = "" ];
then
    versions=(
        '6.5.0'
        '5.5.14'
    )
else
    versions=("$1")
fi

num_vers=$(expr ${#versions[@]} - 1)

for((i=0; i<=num_vers; i++));
do
    version="${versions[$i]}"
    PUPPET_VERSION=${version} bundle install
    echo "Puppet Agent Version: ${version}"

  for file in `ls $nodesdir`;
  do
      node=$(echo $file | sed -e 's/.yml//g')
      mkdir -p ${logdir}/pv${version}
      logfile="${logdir}/pv${version}/${node}-dispatcher.log"

      echo "  Running test dispatcher_spec for ${node}"
      PUPPET_VERSION=${version} \
      BEAKER_set=${node} \
      bundle exec rspec spec/acceptance/dispatcher/dispatcher_spec.rb > ${logfile} 2>&1
  done
done