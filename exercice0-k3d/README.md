# Exercice 0 : préparer son environnement d'orchestration avec K3d

Cette préparation d'environnement cible la mise en place d'un cluster Kubernetes à partir de [K3d](https://k3d.io/) qui s'appuie sur la distribution légère [K3s](https://k3s.io/). [K3d](https://k3d.io/) sera utilisé comme solution _Dind_ => [Docker](https://www.docker.com/ "Docker") in [Docker](https://www.docker.com/ "Docker"). Cette approche _Dind_ permet de déployer un cluster Kubernetes multi-nœuds directement sur votre poste développeur. Tous les nœuds (maître et de travail) sont encapsulés dans un conteneur [Docker](https://www.docker.com/ "Docker"). L'avantage est de pouvoir profiter des performances des conteneurs (rapidité et occupation mémoire réduite) pour créer des nœuds.

Comme précisé en introduction, l'ensemble des expérimentations ont été testées depuis macOS et Linux. L'adaptation sous Windows n'est pas insurmontable, il faudra adapter certains scripts.

> **Il est important de signaler que cette préparation d'environnement ne peut être appliquée pour une mise en production.**

## But

* Créer un cluster [K3d](https://k3d.io/)
* Installer les outils de gestion **kubectl** et [K9s](https://k9scli.io/)

## Étapes à suivre

[K3d](https://k3d.io/) sera donc utilisé pour créer notre cluster Kubernetes. Il s'agit d'un outil en ligne de commande qui encapsule la création des nœuds dans des conteneurs [Docker](https://www.docker.com/ "Docker").

Ci-dessous sont données les instructions d'installation de [K3d](https://k3d.io/) pour Linux et macOS.

---

**macOS** : pour installer [K3d](https://k3d.io/) via [Homebrew](https://brew.sh/) :

```
$ brew install k3d
```

**Linux** : pour installer [K3d](https://k3d.io/) :

```
$ wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
```

---

* Pour s'assurer que [K3d](https://k3d.io/) est correctement installé, exécuter les deux commandes suivantes :

```
$ k3d version
k3d version v5.2.2
k3s version v1.21.7-k3s1 (default)
```

Nous allons créer un cluster Kubernetes composé de trois nœuds dont un sera dédié au nœud maître et les deux autres seront dédiés aux nœuds de travail. Sous [K3d](https://k3d.io/), un nœud de travail est intitulé `agent` et un nœud maître est intitulé `server`.

* Créer un cluster Kubernetes via [K3d](https://k3d.io/) qui s'appelera `mycluster` :

```
$ k3d cluster create mycluster -p "8081:30001@server:0" --agents 2 --servers 1
```

Cette commande crée un cluster Kubernetes appelé `mycluster`. Il contient deux nœuds de travail (`--agents 2`) et un nœud maître (`--servers 1`). L'option `-p "8081:30001@server:0"` permet d'exposer le port `30001` du cluster vers le port `8001` du poste de développeur.

Afin que nous puissions accéder au cluster Kubernetes, nous devons récupérer un fichier d'accès qui contiendra des informations comme les autorisations pour les outils clients. Ce fichier d'accès permet de communiquer avec le composant *API Server* d'un cluster.

* Se placer à la racine du dossier du dépôt de ce tutoriel et exécuter la ligne de commande suivante pour récupérer ce fichier d'accès :

```
$ k3d kubeconfig get mycluster > k3s.yaml
```

Nous avons désormais un cluster Kubernetes, mais nous ne disposns pas encore des outils pour interagir avec celui-ci. Nous détaillons ci-après comment installer les outils de gestion **kubectl** et [K9s](https://k9scli.io/) sur votre poste de développeur. Leurs utilisations seront détaillées dans l'exercice suivant.

**kubectl** et [K9s](https://k9scli.io/) sont des outils qui communiquent avec le composant *API Server* et nécessitent d'accéder au fichier *k3s.yaml* obtenu précédemment.

### Installation kubectl 

**kubectl** est un outil en ligne de commande (CLI) qui permet d'interagir avec un cluster Kubernetes via le composant **kube-apiserver**.

---

**macOS** : pour installer **kubectl** via [Homebrew](https://brew.sh/) :

```
$ brew install kubectl
```

**Linux** : pour installer **kubectl** sur n'importe quelle distribution Linux :

```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
$ chmod +x ./kubectl
$ sudo mv ./kubectl /usr/local/bin/kubectl
$ kubectl version --client
```

---

* Pour tester si **kubectl** est correctement installé :

```
$ export KUBECONFIG=$PWD/k3s.yaml
$ kubectl top nodes
NAME                     CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
k3d-mycluster-agent-0    58m          2%     165Mi           11%
k3d-mycluster-agent-1    59m          2%     144Mi           9%
k3d-mycluster-server-0   202m         10%    552Mi           37%
```

La première ligne de commande permet d'indiquer à **kubectl** où se trouve le fichier d'accès au cluster Kubernetes. Cette commande n'est à réaliser qu'une seule fois à l'ouvertue de votre terminal. Le seconde ligne de commande permet d'obtenir des informations sur les ressources utilisées par des objets gérés par Kubernetes (ici l'objet est un nœud).

### Installation K9s

[K9s](https://k9scli.io/) est un gestionnaire de cluster Kubernetes qui a la particularité de fonctionner dans la console. L'interface utilisateur est très simpliste, mais permet de retourner en continu l'état du cluster.

---

**macOS** : pour installer **K9s** via [Homebrew](https://brew.sh/) :

```
$ brew install k9s
```

**Linux** : pour installer **K9s** :

```
$ wget https://github.com/derailed/k9s/releases/download/v0.25.15/k9s_Linux_x86_64.tar.gz
$ tar xzf k9s_Linux_x86_64.tar.gz
```

---

* Pour tester si **K9s** est correctement installé, depuis un autre terminal :

```
$ export KUBECONFIG=./k3s.yaml
$ k9s
```

Vous devriez obtenir le même résultat que sur la figure ci-dessous.

![Outil K9s affichant les Pods déployés sur le cluster K8s d'une distribution K3d](../images/k9s-k3d.png "K9s pour gérer votre cluster K8s d'une distribution K3d")

## Bilan de l'exercice

À cette étape, vous disposez :

* d'un cluster Kubernetes avec trois nœuds dont un pour le maître et deux autres pour les nœuds de travail ;
* de deux outils pour contrôler notre cluster Kubernetes.

## Ressources

* https://betterprogramming.pub/local-k3s-cluster-made-easy-with-multipass-108bf6ce577c
* https://k33g.gitlab.io/articles/2020-02-21-K3S-01-CLUSTER.html