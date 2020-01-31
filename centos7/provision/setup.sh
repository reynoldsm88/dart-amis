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
    echo "installing docker"
    sudo groupadd docker
    sudo usermod -aG docker centos
    sudo yum install -y docker
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

setup
install_git
setup_utils
install_pip
install_docker
install_java
install_scala
install_sbt
disable_selinux
finalize