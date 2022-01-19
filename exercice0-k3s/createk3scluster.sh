#!/bin/sh

PREFIX_MASTER=k8s-master
PREFIX_NODE=k8s-workernode-

createVM()
{
    multipass launch -n $1 --cpus 1 --mem $2'G'
    if ! [[ -z "$3" ]]
    then
        multipass exec $1 -- sudo sed -ri 's/nameserver.*/nameserver '$3'/g' /etc/resolv.conf
    fi
}

installK3s()
{
    multipass --verbose exec $1 -- sh -c " curl -sfL https://get.k3s.io | $2 sh - "
}

if [ $# -eq 0 ]; then
    echo "😭 Integers required to specify the cluster sizing."
    exit 1
fi

if ! [[ "$1" =~ ^[0-9]+$ ]]
then
    echo "😭 Parameter must be an integer."
    exit 1;
fi

if [ "$1" -eq 0 ]
then
    echo "😭 What I am used for!! You want an empty cluster."
    exit 1;
fi

let clusterSizing=$1-1

# Create master node.
createVM ${PREFIX_MASTER} 2 $2
installK3s ${PREFIX_MASTER}
TOKEN=$(multipass exec ${PREFIX_MASTER} sudo cat /var/lib/rancher/k3s/server/node-token)
IP=$(multipass info ${PREFIX_MASTER} | grep IPv4 | awk '{print $2}')


echo "✅ K3s initialized on ${PREFIX_MASTER}"
echo "Token: ${TOKEN}"
echo "IP: ${IP}"

for ((i=1;i<=clusterSizing;i++)); do
    createVM $PREFIX_NODE$i 1 $2
    installK3s $PREFIX_NODE$i "K3S_URL='https://$IP:6443' K3S_TOKEN='$TOKEN'"
    echo "✅ $PREFIX_NODE$i has joined the Cluster"
done

multipass exec ${PREFIX_MASTER} sudo cat /etc/rancher/k3s/k3s.yaml > k3s.yaml
sed -i '' "s/127.0.0.1/$IP/" k3s.yaml
