#!/bin/bash

pidFile="/etc/build-server/pid"
startScript="/etc/build-server/start.sh"

start() {
	if [ -f $pidFile ];
	then
		echo "$pidFile already exists. Process is probably still running."
	else
		rm -f $startScript
		touch $startScript
		echo "cd /etc/build-server" >> $startScript
		# -DDOCKER_CERT_PATH=/home/build/.docker
		echo "java -DDOCKER_HOST=http://127.0.0.1:4243 -jar build-server.jar >> server.log 2>&1 &" >> $startScript
		echo "echo \$! > $pidFile" >> $startScript
		chmod +x $startScript
		chown build:build $startScript

		echo "Starting build-server..."
		su -l build -c $startScript
		rm -f $startScript

		sleep 1
		echo "Build-server started!"
	fi
}

stop() {
	if [ -f $pidFile ];
	then
		echo "Stopping build-server..."
		pid=`cat ${pidFile}`
		kill $pid
		rm $pidFile

		sleep 1
		echo "Build-server stopped!"
	else
		echo "$pidFile does not exists. Process is probably not running."
	fi
}

build() {
	su build << 'EOF'
	rm -rf /etc/build-server/tmp
	mkdir /etc/build-server/tmp
	cd /etc/build-server/tmp
	git clone https://github.com/devhub-tud/build-server.git
	cd build-server
	mvn clean package -DskipTests=true
EOF
}

deploy() {
	su build << 'EOF'
	cp -rf /etc/build-server/config/config.properties /etc/build-server/config/config_backup.properties
	cp -rf /etc/build-server/tmp/build-server/build-server/target/build-server-distribution/build-server/. /etc/build-server/
	cp -rf /etc/build-server/config/config_backup.properties /etc/build-server/config/config.properties
	rm -rf /etc/build-server/tmp
EOF
}

watch() {
	tail -f -n 1000 /etc/build-server/server.log
}

case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	status)
		status build-server
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
