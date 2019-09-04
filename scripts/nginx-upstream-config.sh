#!/usr/bin/env bash

[ -f /etc/nginx/sites-available/default ] && { BACKEND_SOCKET=`cat /etc/nginx/sites-available/default | grep 'upstream nomad_backend'`
    if [ "${BACKEND_SOCKET}" == "" ];
        then
            echo "upstream nomad_backend { $1 }" >> /etc/nginx/sites-available/default
        else
            sed -i "s/${BACKEND_SOCKET}/upstream nomad_backend { $1 }/g" /etc/nginx/sites-available/default
    fi
}
