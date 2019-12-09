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
    sudo echo "#!/bin/bash" >> $USER_HOME/.bashrc

    ssh-keygen -b 4096 -t rsa -f $USER_HOME/.ssh/id_rsa -q -N "" -P "" -C michael.reynolds@twosixlabs.com
    cat $USER_HOME/.ssh/id_rsa.pub >> $USER_HOME/.ssh/authorized_keys
}

function install_git {
    echo "installing git"
    sudo yum install -y git-core
    curl -L -o $USER_HOME/.git-completion.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
    echo "
if [ -f ~/.git-completion.sh ]; then
  . ~/.git-completion.sh
fi
    " >> $USER_HOME/.bashrc
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
    sudo echo "export SBT_HOME="$USER_HOME/tools/sbt >> $USER_HOME/.bashrc
    sudo echo 'export PATH=$PATH:'$USER_HOME/tools/sbt/bin >> $USER_HOME/.bashrc
    sudo echo 'export SBT_OPTS="-Xms2G -Xmx4G"' >> $USER_HOME/.bashrc
    sudo chmod -R 755 $USER_HOME/tools/sbt
}

function install_docker {
    echo "installing docker"
    sudo groupadd docker
    sudo usermod -aG docker centos
    sudo yum install -y docker
    sudo /usr/local/bin/pip3 install docker-compose
    sudo echo "#!/bin/bash" >> $USER_HOME/etc/docker-service.sh
    sudo echo "sudo service docker start" >> $USER_HOME/etc/docker-service.sh

    echo "# echo <> | docker login -u <> --password-stdin" >> $USER_HOME/.bashrc
    sudo chmod -R u+x $USER_HOME/etc
    sudo echo "$USER_HOME/etc/docker-service.sh"
}

function setup_utils {
    git clone https://github.com/reynoldsm88/sanity-scripts.git utils
    chmod -R u+x utils
    echo 'PATH=$PATH:'$USER_HOME/utils >> $USER_HOME/.bashrc
}

function finalize {
    sbt clean
    rm -r -f target
    rm -r -f project
    sudo chown -R centos:centos $USER_HOME
    source $USER_HOME/.bashrc
}

setup
install_git
setup_utils
install_pip
install_docker
install_java
install_scala
install_sbt
finalize