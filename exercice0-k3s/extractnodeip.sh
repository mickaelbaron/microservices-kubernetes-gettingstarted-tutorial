#!/bin/sh

# We suppose we are using Multipass only for our experimentation.
vm_length=$(multipass list | grep k8s | wc -l)

# First one is reserved for the master node
export k8s_master_ip=$(multipass info k8s-master | grep IPv4 | awk '{print $2}')
echo k8s-master 🧑: k8s_master_ip=$k8s_master_ip 

let vm_length=vm_length-1
for ((i=1;i<=vm_length;i++)); do
    value=$(multipass info k8s'-'workernode'-'${i} | grep IPv4 | awk '{print $2}')
    echo k8s'-'workernode${i}'-'ip 👷: k8s_workernode${i}_ip=$value
    export k8s_workernode${i}_ip=$value
done

