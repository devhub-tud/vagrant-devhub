#!/bin/bash

pidFile="/etc/devhub-server/pid"
startScript="/etc/devhub-server/start.sh"

start() {
        if [ -f $pidFile ];
        then
                echo "$pidFile already exists. Process is probably still running."
        else
                rm -f $startScript
                touch $startScript
                chown devhub:devhub $startScript
                echo "cd /etc/devhub-server" >> $startScript
                echo "java -jar devhub-server.jar >> server.log 2>&1 &" >> $startScript
                echo "echo \$! > $pidFile" >> $startScript
                chmod +x $startScript

                echo "Starting devhub-server..."
                su -l devhub -c $startScript
                rm -f $startScript

                sleep 1
                echo "Devhub-server started!"
        fi
}

stop() {
        if [ -f $pidFile ];
        then
                echo "Stopping devhub-server..."
                pid=`cat ${pidFile}`
                kill $pid
                rm $pidFile

                sleep 1
                echo "Devhub-server stopped!"
        else
                echo "$pidFile does not exists. Process is probably not running."
        fi
}

build() {
        su devhub << 'EOF'
        rm -rf /etc/devhub-server/tmp
        mkdir /etc/devhub-server/tmp

        cd /etc/devhub-server/tmp
        git clone --recursive https://github.com/devhub-tud/devhub.git
        cd devhub
        mvn clean generate-sources package -DskipTests=true
EOF
}

deploy() {
        su devhub << 'EOF'
        cp -f /etc/devhub-server/config/persistence.properties /etc/devhub-server/config/persistence_backup.properties
        cp -rf /etc/devhub-server/tmp/devhub/target/devhub-server-distribution/devhub-server/. /etc/devhub-server/.
        mv /etc/devhub-server/config/persistence_backup.properties /etc/devhub-server/config/persistence.properties
        rm -rf /etc/devhub-server/tmp
EOF
}

watch() {
        tail -n 1000 -f /etc/devhub-server/server.log
}

case "$1" in
        start)
                start
                ;;
        stop)
                stop
                ;;
        status)
                status devhub-server
                ;;
        deploy|redeploy)
                build
                stop
                deploy
                start
                ;;
        restart|reload|condrestart)
                stop
                start
                ;;
        watch)
                watch
                ;;
        *)
                echo $"Usage: $0 {start|stop|restart|reload|status}"
                exit 1

esac
exit 0
