#!/bin/bash +x

startdir=$(pwd)
rootdir=$(dirname $0)
nodesdir="${rootdir}/nodesets"
logdir="${rootdir}/log"

if [ "$1" = "" ] || [ "$1" = "all" ];
then
    specs=(
        'create_aem_spec'
        'start_env_spec'
        'license_spec'
        'file_crx_package_spec'
        'file_osgi_spec'
        'console_osgi_spec'
        'sling_resource_spec'
        'crx_package_spec'
        'replication_spec'
        'update_aem_spec'
        'update_env_spec'
        'destroy_spec'
    )
else
    specs=("$1")
fi

if [ "$2" = "" ];
then
    versions=(
        '1.2.0'
        '1.3.0'
        '1.4.0'
        '1.5.0'
        '1.6.0'
        '1.7.0'
        '1.8.0'
    )
else
    versions=("$2")
fi

destroy=no
provision=yes
num_specs=$(expr ${#specs[@]} - 1)
num_vers=$(expr ${#versions[@]} - 1)

for((i=0; i<=num_vers; i++));
do
    version="${versions[$i]}"
    echo "Puppet Agent Version: ${version}"

    for file in `ls $nodesdir`;
    do
        node=$(echo $file | sed -e 's/.yml//g')
        echo "    Node: ${node}"

        for ((j=0; j<=num_specs; j++));
        do
            mkdir -p ${logdir}/pv${version}/${node}
            spec="${specs[$j]}"
            logfile="${logdir}/pv${version}/${node}/${spec}.log"

            if [ $j = $num_specs ];
            then
                destroy=yes
            else
                destroy=no
            fi
            reprov="$((j % 5))"
            if [ $j = 0 ] || [ $reprov = 0 ];
            then
                provision=yes
            else
                provision=no
            fi

            echo "        Test: ${spec}"
            PUPPET_INSTALL_VERSION=${version} \
            BEAKER_set=${node} \
            BEAKER_provision=${provision} \
            BEAKER_destroy=${destroy} \
            bundle exec rspec spec/acceptance/aem/${spec}.rb > ${logfile} 2>&1

            if [ $? != 0 ];
            then
                cd .vagrant/beaker_vagrant_files/${node}.yml
                vagrant destroy --force
                cd ${startdir}
                echo "        Re-test: ${spec}"
                PUPPET_INSTALL_VERSION=${version} BEAKER_set=${node} BEAKER_provision=yes BEAKER_destroy=${destroy} bundle exec rspec spec/acceptance/aem/${spec}.rb >> ${logfile} 2>&1
                if [ $? != 0 ];
                then
                    cd .vagrant/beaker_vagrant_files/${node}.yml
                    vagrant halt
                    cd ${startdir}
                fi
            fi
        done
    done
done