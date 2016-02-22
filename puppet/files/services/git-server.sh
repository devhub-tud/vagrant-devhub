#!/bin/bash

pidFile="/etc/git-server/pid"
startScript="/etc/git-server/start.sh"

start() {
        if [ -f $pidFile ];
        then
                echo "$pidFile already exists. Process is probably still running."
        else
                rm -f $startScript
                touch $startScript
                chown git:git $startScript
                echo "cd /etc/git-server" >> $startScript
                echo "java -jar git-server.jar >> server.log 2>&1 &" >> $startScript
                echo "echo \$! > $pidFile" >> $startScript
                chmod +x $startScript

                echo "Starting git-server..."
                su -l git -c $startScript
                rm -f $startScript

                sleep 1
                echo "Git-server started!"
        fi
}

stop() {
        if [ -f $pidFile ];
        then
                echo "Stopping git-server..."
                pid=`cat ${pidFile}`
                kill $pid
                rm $pidFile

                sleep 1
                echo "Git-server stopped!"
        else
                echo "$pidFile does not exists. Process is probably not running."
        fi
}

build() {
        su git << 'EOF'
        rm -rf /etc/git-server/tmp
        mkdir /etc/git-server/tmp
        cd /etc/git-server/tmp
        git clone https://github.com/devhub-tud/git-server.git
        cd git-server
        mvn clean package -U -DskipTests=true
EOF
}

deploy() {
        su git << 'EOF'
        cp -f /etc/git-server/config/config.properties /etc/git-server/config/config_backup.properties
        cp -rf /etc/git-server/tmp/git-server/git-server/target/git-server-distribution/git-server/. /etc/git-server/
        mv /etc/git-server/config/config_backup.properties /etc/git-server/config/config.properties
        rm -rf /etc/git-server/tmp
EOF
}

watch() {
        tail -f -n 2000 /etc/git-server/server.log
}


case "$1" in
        start)
                start
                ;;
        stop)
                stop
                ;;
        status)
                status git-server
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
