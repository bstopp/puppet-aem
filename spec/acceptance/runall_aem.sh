#!/bin/bash

startdir=$(pwd)
rootdir=$(dirname $0)
nodesdir="${rootdir}/nodesets"
logdir="${rootdir}/logs"

specs=(
    'create_aem_spec'
    'start_env_spec'
    'license_spec'
    'file_osgi_spec'
    'console_osgi_spec'
    'sling_resource_spec'
    'replication_spec'
    'update_aem_spec'
    'update_env_spec'
    'destroy_spec'
)

destroy=no
provision=yes
num_specs=$(expr ${#specs[@]} - 1)

for file in `ls $nodesdir`;
do
    for ((i=0; i<=num_specs; i++));
    do
        node=$(echo $file | sed -e 's/.yml//g')
        mkdir -p ${logdir}/${node}
        spec="${specs[$i]}"
        logfile="${logdir}/${node}/${spec}.log"

        if [ $i = $num_specs ];
        then
            destroy=yes
        else
            destroy=no
        fi
        reprov="$((i % 5))"
        if [ $i = 0 ] || [ $reprov = 0 ];
        then
            provision=yes
        else
            provision=no
        fi

        echo "Running test ${spec} for ${node}"
        BEAKER_set=${node} BEAKER_provision=${provision} BEAKER_destroy=${destroy} bundle exec rspec spec/acceptance/aem/${spec}.rb > ${logfile} 2>>&1
        if [ $? != 0 ];
        then
            cd .vagrant/beaker_vagrant_files/${node}.yml
            vagrant destroy --force
            cd ${startdir}
            echo "Re-Running test ${spec} for ${node}"
            BEAKER_set=${node} BEAKER_provision=yes BEAKER_destroy=${destroy} bundle exec rspec spec/acceptance/aem/${spec}.rb >> ${logfile} 2>>&1
            if [ $? != 0 ];
            then
                cd .vagrant/beaker_vagrant_files/${node}.yml
                vagrant halt
                cd ${startdir}
            fi
        fi
    done
done