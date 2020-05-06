#!/bin/bash
export USER_HOME="/home/centos"

function setup {
    echo "setting up home directory $USER_HOME"
    mkdir -p $USER_HOME/{tools,etc}
    echo "running update $USER_HOME"
    sudo yum update -y
    echo "running install $USER_HOME"
    sudo yum install -y make
    sudo yum install -y vim
    sudo yum install -y net-tools
    sudo yum install -y telnet
    sudo echo "vm.max_map_count = 262144" >> /etc/sysctl.conf

    ssh-keygen -b 4096 -t rsa -f $USER_HOME/.ssh/id_rsa -q -N "" -P "" -C michael.reynolds@twosixlabs.com
    cat $USER_HOME/.ssh/id_rsa.pub >> $USER_HOME/.ssh/authorized_keys
}

function install_git {
    echo "installing git"
    sudo yum install -y git-core
    curl -L -o $USER_HOME/.git-completion.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
    chmod +x $USER_HOME/.git-completion.sh
}

function install_pip {
    echo "installing python stuff"
    sudo yum install -y python3
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    sudo python3 get-pip.py
    rm get-pip.py
}

function install_java {
    echo "installing java"
    sudo yum install -y java-1.8.0-openjdk-devel.x86_64
}

function install_scala {
    echo "installing scala"
    curl -O -L https://downloads.lightbend.com/scala/2.12.10/scala-2.12.10.tgz
    SCALA_TAR=$(find . -name scala*.tgz)
    tar -xf $SCALA_TAR
    rm $SCALA_TAR

    SCALA_INSTALL=$(find . -name scala-*)
    mv $SCALA_INSTALL $USER_HOME/tools/scala
    sudo echo "export SCALA_HOME="$USER_HOME/tools/scala >> $USER_HOME/.bashrc
    sudo echo 'export PATH=$PATH:'$USER_HOME/tools/scala/bin >> $USER_HOME/.bashrc

    sudo chmod -R 755 $USER_HOME/tools/scala
}

function install_sbt {
    echo "installing sbt"
    curl -O -L https://piccolo.link/sbt-1.2.6.tgz
    SBT_TAR=$(find . -name sbt*.tgz)
    tar -xf $SBT_TAR
    rm $SBT_TAR

    SBT_INSTALL=sbt
    mv $SBT_INSTALL $USER_HOME/tools/sbt
    sudo chmod -R 755 $USER_HOME/tools/sbt
}

function install_docker {
    echo "installing latest docker community edition"

    sudo groupadd docker
    sudo usermod -aG docker centos

    sudo yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

    sudo yum install -y yum-utils \
         device-mapper-persistent-data \
         lvm2

    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    sudo yum install -y docker-ce docker-ce-cli containerd.io

    sudo /usr/local/bin/pip3 install docker-compose
    sudo mkdir $USER_HOME/etc
    sudo echo "#!/bin/bash" >> $USER_HOME/etc/docker-service.sh
    sudo echo "sudo service docker start" >> $USER_HOME/etc/docker-service.sh
    sudo chmod -R u+x $USER_HOME/etc
}

function setup_utils {
    git clone https://github.com/reynoldsm88/sanity-scripts.git utils
    chmod -R u+x utils
}

function finalize {
    sbt clean
    rm -r -f target
    rm -r -f project
    sudo chown -R centos:centos $USER_HOME
    
    # download our bashrc so that we can differentiate interactive and non interactive terminals
    if [ -f "$USER_HOME/.bashrc" ]; then
        echo "removing existing .bashrc file"
        rm $USER_HOME/.bashrc
    fi

    curl -o $USER_HOME/.bashrc https://raw.githubusercontent.com/reynoldsm88/dart-amis/master/centos7/bin/bashrc
    sudo chown centos:centos $USER_HOME/.bashrc
    chmod u+x $USER_HOME/.bashrc
    source $USER_HOME/.bashrc
}

function disable_selinux {
    sudo echo "SELINUX=disabled" > /etc/selinux/config
    sudo echo "SELINUXTYPE=targeted" >> /etc/selinux/config
}

function create_java_keystore {
    CERTIFICATE_CN=localhost
    PASSWORD=changeme
    CERT_DIR=/opt/app/certs/

    mkdir -p $CERT_DIR

    # Generate jks keystore with a private key
    keytool -genkey -noprompt \
    -alias server-key \
    -dname "CN=$CERTIFICATE_CN" \
    -keystore $CERT_DIR/server.keystore.jks \
    -storepass "$PASSWORD" \
    -keypass "$PASSWORD" \
    -validity 365 \
    -deststoretype pkcs12 \
    -keyalg RSA -genkey

    ## Generate private key and cert for Certificate Authority
    ## The req command primarily creates and processes certificate requests in PKCS#10 format.
    ## It can additionally create self signed certificates for use as root CAs for example.
    openssl req -new -x509 -keyout ca-key -out ca-cert -days 365 -passout pass:"$PASSWORD" -subj "/CN=$CERTIFICATE_CN"

    ## Import Certificate authority certificate into server jks and create certstore jks for client
    keytool -keystore $CERT_DIR/server.truststore.jks -alias CARoot -import -file ca-cert -keypass "$PASSWORD" -storepass "$PASSWORD" -noprompt
    keytool -keystore $CERT_DIR/client.truststore.jks -alias CARoot -import -file ca-cert -keypass "$PASSWORD" -storepass "$PASSWORD" -noprompt

    # Generate a certificate request
    keytool -keystore $CERT_DIR/server.keystore.jks -alias server-key -certreq -file cert-file -keypass "$PASSWORD" -storepass "$PASSWORD" -noprompt

    # Signed a certificagte request with previously created Certificate Authority
    openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days 365 -CAcreateserial -passin pass:"$PASSWORD"

    # Importing signed certificate
    keytool -keystore $CERT_DIR/server.keystore.jks -alias CARoot -import -file ca-cert -storepass "$PASSWORD" -noprompt -keypass "$PASSWORD"
    keytool -keystore $CERT_DIR/server.keystore.jks -alias server-key -import -file cert-signed -storepass "$PASSWORD" -noprompt -keypass "$PASSWORD"

    echo "cert dir output"
    ls -al $CERT_DIR
}

setup
install_git
setup_utils
install_pip
install_java
install_scala
install_sbt
create_java_keystore
install_docker
disable_selinux
finalize