#!/bin/bash
export USER_HOME="/home/$SSH_USERNAME"

function setup {
    echo "setting up home directory $USER_HOME"
    mkdir -p $USER_HOME/{tools,etc}
    echo "running update $USER_HOME"
    sudo zypper update -y
    echo "running install $USER_HOME"
    sudo zypper install -y make
    sudo echo "vm.max_map_count = 262144" >> /etc/sysctl.conf

    ssh-keygen -b 4096 -t rsa -f $USER_HOME/.ssh/id_rsa -q -N "" -P "" -C michael.reynolds@twosixlabs.com
    cat $USER_HOME/.ssh/id_rsa.pub >> $USER_HOME/.ssh/authorized_keys

    sudo echo "#!/bin/bash" >> $USER_HOME/etc/docker-service.sh
    sudo echo "sudo service docker start" >> $USER_HOME/etc/docker-service.sh
    sudo echo "#!/bin/bash" >> $USER_HOME/.profile
}

function install_git {
    echo "installing git"
    sudo zypper install -y git-core
    curl -L -o $USER_HOME/.git-completion.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
    echo "
if [ -f ~/.git-completion.sh ]; then
  . ~/.git-completion.sh
fi
    " >> $USER_HOME/.profile
}

function install_pip {
    echo "installing pip"
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    sudo python3 get-pip.py
    rm get-pip.py
}

function install_java {
    echo "installing java"
    sudo zypper install -y java-1_8_0-openjdk-devel
}

function install_scala {
    echo "installing scala"
    curl -O -L https://downloads.lightbend.com/scala/2.12.10/scala-2.12.10.tgz
    SCALA_TAR=$(find . -name scala*.tgz)
    tar -xf $SCALA_TAR
    rm $SCALA_TAR

    SCALA_INSTALL=$(find . -name scala-*)
    mv $SCALA_INSTALL $USER_HOME/tools/scala
    sudo echo "export SCALA_HOME="$USER_HOME/tools/scala >> $USER_HOME/.profile
    sudo echo 'export PATH=$PATH:'$USER_HOME/tools/scala/bin >> $USER_HOME/.profile
}

function install_sbt {
    echo "installing sbt"
    curl -O -L https://piccolo.link/sbt-1.2.6.tgz
    SBT_TAR=$(find . -name sbt*.tgz)
    tar -xf $SBT_TAR
    rm $SBT_TAR

    SBT_INSTALL=sbt
    mv $SBT_INSTALL $USER_HOME/tools/sbt
    sudo echo "export SBT_HOME="$USER_HOME/tools/sbt >> $USER_HOME/.profile
    sudo echo 'export PATH=$PATH:'$USER_HOME/tools/sbt/bin >> $USER_HOME/.profile
    sudo echo 'export SBT_OPTS="-Xms2G -Xmx4G"' >> $USER_HOME/.profile
}

function install_docker {
    echo "installing docker"
    sudo zypper install -y docker
    sudo pip3 install docker-compose
}

function setup_utils {
    git clone https://github.com/reynoldsm88/sanity-scripts.git utils
    chmod -R u+x utils
    echo 'PATH=$PATH:'$USER_HOME/utils >> $USER_HOME/.profile
}

function set_default_login_commands {
    echo "sudo service docker start" >> $USER_HOME/.profile
    echo "# docker login -u ... -p ..."
}

function finalize {
    source $USER_HOME/.profile
    sbt clean
    rm -r -f target
    rm -r -f project
}

setup
install_git
setup_utils
install_pip
install_docker
install_java
install_scala
install_sbt
set_default_login_commands
finalize