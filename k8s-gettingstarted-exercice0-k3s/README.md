# Exercice 0 : préparer son environnement d'orchestration avec K3s

Cette préparation d'environnement cible la mise en place d'un cluster Kubernetes à partir de la distribution légère [K3s](https://k3s.io/). Nous nous appuierons sur [MultiPass](https://multipass.run/) pour créer trois machines virtuelles sur votre poste développeur qui serviront à héberger notre cluster. Comme nous ne déploierons pas de grosses applications sur notre cluster, les ressources allouées aux machines virtuelles seront réduites (1 coeur et 1 Go de mémoire).

Comme précisé en introduction, l'ensemble des expérimentations ont été testées depuis macOS et Linux. L'adaptation sous Windows n'est pas insurmontable, il faudra adapter les scripts.

## But

* Créer des machines virtuelles
* Créer un cluster Kubernetes avec la distribution [K3s](https://k3s.io/)
* Installer les outils de gestion kubectl et [K9s](https://k9scli.io/)

## Étapes à suivre

> La procédure d'installation de [K3s](https://k3s.io/) est basée sur l'article de Philippe Charrière que vous pouvez retrouver ici : https://k33g.gitlab.io/articles/2020-02-21-K3S-01-CLUSTER.html

Nous utiliserons [MultiPass](https://multipass.run/) pour créer des machines virtuelles. Il s'agit d'un gestionnaire de machines virtuelles créé par [Canonical](https://canonical.com/) l'entreprise qui est derrière la distribution Linux [Ubuntu](https://ubuntu.com). [MultiPass](https://multipass.run/) s'appuie sur les hyperviseurs KVM pour Linux, Hyper-V pour Windows et HyperKit sur macOS pour exécuter une machine virtuelle. 

Nous donnons ci-dessous les instructions d'installation pour Linux et macOS.

* **macOS** : pour installer [MultiPass](https://multipass.run/) via [Homebrew](https://brew.sh/) :

```
$ brew install --cask multipass
```

* **Linux** : pour installer [MultiPass](https://multipass.run/) via [snap](https://snapcraft.io/) :

```
$ sudo snap install multipass
```

* Pour s'assurer que [MultiPass](https://multipass.run/) est correctement installé, exécuter les deux commandes suivantes :

```
$ multipass
Usage: multipass [options] <command>
Create, control and connect to Ubuntu instances.

This is a command line utility for multipass, a
service that manages Ubuntu instances.

Options:
  -h, --help     Displays help on commandline options.
  --help-all     Displays help including Qt specific options.
  -v, --verbose  Increase logging verbosity. Repeat the 'v' in the short option
                 for more detail. Maximum verbosity is obtained with 4 (or more)
                 v's, i.e. -vvvv.

Available commands:
  alias     Create an alias
  aliases   List available aliases
  delete    Delete instances
  exec      Run a command on an instance
  find      Display available images to create instances from
  get       Get a configuration setting
  help      Display help about a command
  info      Display information about instances
  launch    Create and start an Ubuntu instance
  list      List all available instances
  mount     Mount a local directory in the instance
  networks  List available network interfaces
  purge     Purge all deleted instances permanently
  recover   Recover deleted instances
  restart   Restart instances
  set       Set a configuration setting
  shell     Open a shell on a running instance
  start     Start instances
  stop      Stop running instances
  suspend   Suspend running instances
  transfer  Transfer files between the host and instances
  umount    Unmount a directory from an instance
  unalias   Remove an alias
  version   Show version details

$ multipass version
multipass   1.8.1+mac
multipassd  1.8.1+mac
```

* Nous allons maintenant créer trois machines virtuelles dont une sera dédiée au nœud maître (`k8s-master`) et les deux autres seront dédiées aux nœuds de travail (`k8s-workernode-1` et `k8s-workernode-2`) :

```
$ master_name="k8s-master"
$ workernode1_name="k8s-workernode-1"
$ workernode2_name="k8s-workernode-2"

$ multipass launch -n ${master_name} --cpus 1 --mem 2G
$ multipass launch -n ${workernode1_name} --cpus 1 --mem 1G
$ multipass launch -n ${workernode2_name} --cpus 1 --mem 1G
```

Le temps de création peut-être un peu long puisque [MultiPass](https://multipass.run/) va commencer par télécharger l'image Ubuntu et réaliser les installations.

* Assurons-nous que les trois machines virtuelles ont été créées et qu'elles sont démarrées :

```
$ multipass list
Name                    State             IPv4             Image
k8s-master              Running           192.168.64.9     Ubuntu 20.04 LTS
k8s-workernode-1        Running           192.168.64.10    Ubuntu 20.04 LTS
k8s-workernode-2        Running           192.168.64.11    Ubuntu 20.04 LTS
```

* Vérifions également que l'accès au réseau fonctionne (DNS) :

```
$ multipass exec k8s-master ping www.google.fr
PING www.google.fr (142.251.37.35) 56(84) bytes of data.
64 bytes from XYZ (142.251.37.35): icmp_seq=1 ttl=115 time=16.6 ms
64 bytes from XYZ (142.251.37.35): icmp_seq=1 ttl=115 time=16.7 ms
...
```

> Dans le cas où la résolution de noms pose problème, vous pouvez modifier l'IP du serveur DNS depuis le fichier `/etc/resolv.conf`. Les lignes de commande ci-dessous permettent de changer directement l'IP du DNS de chaque machine virtuelle.

```
$ multipass exec ${master_name} -- sudo sed -ri 's/nameserver.*/nameserver 8.8.8.8/g' /etc/resolv.conf
$ multipass exec ${workernode1_name} -- sudo sed -ri 's/nameserver.*/nameserver 8.8.8.8/g' /etc/resolv.conf
$ multipass exec ${workernode2_name} -- sudo sed -ri 's/nameserver.*/nameserver 8.8.8.8/g' /etc/resolv.conf
```

L'accès aux machines virtuelles se fait directement depuis l'outil **multipass**. Si vous souhaitez passer par un accès via SSH, vous devrez configurer chaque machine virtuelle en ajoutant votre clé SSH publique.

* Pour installer [K3s](https://k3s.io/) sur le nœud maître. 

```
$ multipass --verbose exec ${master_name}-- sh -c "
  curl -sfL https://get.k3s.io | sh -
"
```

Le nœud maître étant installé, nous allons pouvoir récupérer un TOKEN d'identification et l'adresse IP du cluster K8s. Ces informations nous serviront pour ajouter des nœuds de travail au cluster (actuellement composé d'un seul nœud).

* Pour obtenir le TOKEN d'identification du cluster et son IP :

```
$ TOKEN=$(multipass exec ${master_name} sudo cat /var/lib/rancher/k3s/server/node-token)
$ IP=$(multipass info ${master_name} | grep IPv4 | awk '{print $2}')
```

* Pour ajouter au cluster le premier nœud de travail :

```
$ multipass --verbose exec ${workernode1_name} -- sh -c "
  curl -sfL https://get.k3s.io | K3S_URL='https://$IP:6443' K3S_TOKEN='$TOKEN' sh -
"
```

* De même pour ajouter le second nœud de travail :

```
$ multipass --verbose exec ${workernode2_name} -- sh -c "
  curl -sfL https://get.k3s.io | K3S_URL='https://$IP:6443' K3S_TOKEN='$TOKEN' sh -
"
```

Vous remarquerez que l'ajout d'un nouveau nœud de travail se fait assez facilement.

* Pour afficher l'état des machines virtuelles : 

```
$ multipass list
Name                    State             IPv4             Image
k8s-master              Running           192.168.64.9     Ubuntu 20.04 LTS
                                          10.42.0.0
                                          10.42.0.1
k8s-workernode-1        Running           192.168.64.10    Ubuntu 20.04 LTS
                                          10.42.1.0
                                          10.42.1.1
k8s-workernode-2        Running           192.168.64.11    Ubuntu 20.04 LTS
                                          10.42.2.0
                                          10.42.2.1
```

Afin que nous puissions accéder au Cluster, nous devons récupérer un fichier d'accès qui contiendra des informations comme les autorisations pour les outils clients.

* Se placer à la racine du dossier du dépôt de ce tutoriel et exécuter les deux lignes de commande suivantes pour récupérer ce fichier d'accès :

```
$ multipass exec ${master_name} sudo cat /etc/rancher/k3s/k3s.yaml > k3s.yaml
sed -i '' "s/127.0.0.1/$IP/" k3s.yaml
```

Toutes les instructions précédentes ont été regroupées dans un fichier script `createk3scluster.sh`. Il permet de paramétrer le nombre de nœuds de travail, la seule limite étant les ressources de votre ordinateur.

TODO

Nous avons désormais un cluster K8s, mais nous ne disposns pas encore des outils pour interagir avec celui-ci. Nous détaillons ci-après comment installer les outils de gestion **kubectl** et **k9s** sur votre poste de développeur. Leurs utilisations seront détaillées dans l'exercice suivant.

### Installation kubectl 

**kubectl** est un outil en ligne de commande (CLI) qui permet d'interagir avec un cluster Kubernetes via le composant **kube-apiserver**.

* **macOS** : pour installer **kubectl** via [Homebrew](https://brew.sh/) :

```
$ brew install kubectl
```

* **Linux** : pour installer **kubectl** sur n'importe quelle distribution Linux :

```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
$ chmod +x ./kubectl
$ sudo mv ./kubectl /usr/local/bin/kubectl
$ kubectl version --client
```

* Pour tester si **kubectl** est correctement installé :

```
$ export KUBECONFIG=./k3s.yaml
$ kubectl top nod
NAME               CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
k8s-master         77m          7%     927Mi           46%
k8s-workernode-1   20m          2%     469Mi           47%
k8s-workernode-2   20m          2%     472Mi           48%
```

La première ligne de commande permet d'indiquer à **kubectl** où se trouve le fichier d'accès au Cluster Kubernetes.

### Installation k9s

**K9s** est un gestionnaire de cluster Kubernetes qui a la particularité de fonctionner dans la console. L'interface utilisateur est très simpliste, mais permet de retourner en continu l'état du cluster.

* **macOS** : pour installer **k9s** via [Homebrew](https://brew.sh/) :

```
$ brew install k9s
```

* **Linux** : pour installer **k9s** :

```
$ wget https://github.com/derailed/k9s/releases/download/v0.25.15/k9s_Linux_x86_64.tar.gz
$ tar xzf k9s_Linux_x86_64.tar.gz
```

* Pour tester si **k9s** est correctement installé, depuis un autre terminal :

```
$ export KUBECONFIG=./k3s.yaml
$ k9s
```

Vous devriez obtenir le même résultat que sur la figure ci-dessous.

![Outil K9s affichant les Pods déployés sur le cluster K8s](../images/k9s.png "K9s pour gérer votre cluster K8s")