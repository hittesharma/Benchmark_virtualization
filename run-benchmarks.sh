#!/bin/bash

ID_RSA_PATH=""
QEMU_VM_IP=""
QEMU_KVM_VM_IP=""

echo 'time,cpu,mem,diskSeq,diskRand,fork,uplink' | tee -a ./results-native.csv ./results-docker.csv ./results-kvm.csv ./results-qemu.csv

ssh-keyscan -H "$QEMU_VM_IP" >> ~/.ssh/known_hosts
ssh-keyscan -H "$QEMU_KVM_VM_IP" >> ~/.ssh/known_hosts

# Run the native benchmark 10 times
for i in {1..10}
do
   echo $(./benchmark.sh) >> ./results-native.csv
done

# Build the Docker Image
docker build -t benchmark-cc:latest .
# Run the Docker benchmark 10 times
for i in {1..10}
do
   echo $(docker run --rm benchmark-cc) >> ./results-docker.csv
done

# Copy benchmark files to KVM VM
scp -i $ID_RSA_PATH ./forksum.c ./benchmark.sh ubuntu@$QEMU_KVM_VM_IP:/tmp
# Ensure benchmark files are executable
ssh -i $ID_RSA_PATH ubuntu@$QEMU_KVM_VM_IP chmod +x /tmp/benchmark.sh
# Run the KVM benchmark 10 times
for i in {1..10}
do
   echo $(ssh -i $ID_RSA_PATH ubuntu@$QEMU_KVM_VM_IP 'cd /tmp/ && sudo /tmp/benchmark.sh') >> ./results-kvm.csv
done

# Copy benchmark files to QEMU VM
scp -i $ID_RSA_PATH ./forksum.c ./benchmark.sh ubuntu@$QEMU_VM_IP:/tmp
# Ensure benchmark files are executable
ssh -i $ID_RSA_PATH ubuntu@$QEMU_VM_IP chmod +x /tmp/benchmark.sh
# Run the QEMU benchmark 10 times
for i in {1..10}
do
   echo $(ssh -i $ID_RSA_PATH ubuntu@$QEMU_VM_IP 'cd /tmp/ && sudo /tmp/benchmark.sh') >> ./results-qemu.csv
done

