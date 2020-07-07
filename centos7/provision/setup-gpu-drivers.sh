#!/usr/bin/env bash

function install_gpu_drivers {

  sudo yum update
  sudo yum install -y gcc kernel-devel-$(uname -r)

  aws s3 cp --recursive s3://ec2-linux-nvidia-drivers/latest/ .
  chmod +x NVIDIA-Linux-x86_64*.run

  sudo /bin/sh ./NVIDIA-Linux-x86_64*.run --ui=none -q -s

  distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

  curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | sudo tee /etc/yum.repos.d/nvidia-docker.repo
  sudo yum install -y nvidia-container-toolkit
  sudo systemctl restart docker

}

function test_gpu_installation {
  sleep 10
  nvidia-smi -q | head
  docker run --gpus all nvidia/cuda:10.0-base nvidia-smi
}

install_gpu_drivers
test_gpu_installation