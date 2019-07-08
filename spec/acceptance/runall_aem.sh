#!/bin/bash +x

startdir=$(pwd)
rootdir=$(dirname $0)
nodesdir="${rootdir}/nodesets"
logdir="${rootdir}/log"

if [ "$1" = "" ]
then
    echo "Usage: $0 <license> [spec] [puppet version]"
    exit
else
    license="$1"
fi

if [ "$2" = "" ] || [ "$2" = "all" ];
then
    spec=('*')
else
    spec=("${2}.rb")
fi

if [ "$3" = "" ];
then
    versions=(
        '6.5.0'
        '5.5.14'
    )
else
    versions=("$3")
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
        echo "  Node: ${node}"

        mkdir -p ${logdir}/pv${version}
        logfile="${logdir}/pv${version}/${node}.log"


        PUPPET_VERSION=${version} \
        AEM_LICENSE=${license} \
        BEAKER_set=${node} \
        bundle exec rspec spec/acceptance/aem/${spec} > ${logfile} 2>&1
    done
done