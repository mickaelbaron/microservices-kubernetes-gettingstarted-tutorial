# Exercice 0 : préparer son environnement d'orchestration avec K3d

Cette préparation d'environnement cible la mise en place d'un cluster Kubernetes à partir de l'outil [K3d](https://k3d.io/) qui s'appuie sur la distribution légère [K3s](https://k3s.io/). [K3d](https://k3d.io/) sera utilisé comme solution _DinD_ => [Docker](https://www.docker.com/ "Docker") in [Docker](https://www.docker.com/ "Docker"). Cette approche _DinD_ permet de déployer un cluster Kubernetes multi-nœuds directement sur votre poste développeur. Tous les nœuds (maître et de travail) sont encapsulés dans un conteneur [Docker](https://www.docker.com/ "Docker"). L'avantage est de pouvoir profiter des performances des conteneurs (rapidité et occupation mémoire réduite) pour créer des nœuds.

Comme précisé en introduction, l'ensemble des expérimentations ont été testées depuis macOS et Linux. L'adaptation sous Windows n'est pas insurmontable, il faudra adapter certains scripts. Tout retour sur une installation sous Windows est le bienvenu.

> **Il est important de signaler que cette préparation d'environnement ne peut être appliquée pour une mise en production. Elle est dédiée au poste du développeur qui souhaite s'assurer que les configurations fonctionnent correctement.**

## But

* Créer un cluster [K3d](https://k3d.io/)
* Installer les outils de gestion **kubectl** et [K9s](https://k9scli.io/)

## Étapes à suivre

[K3d](https://k3d.io/) sera donc utilisé pour créer notre cluster Kubernetes. Il s'agit d'un outil en ligne de commande qui encapsule la création des nœuds dans des conteneurs [Docker](https://www.docker.com/ "Docker").

Ci-dessous sont données les instructions d'installation de [K3d](https://k3d.io/) pour Linux et macOS.

---

**macOS** : pour installer [K3d](https://k3d.io/) via [Homebrew](https://brew.sh/) :

```bash
brew install k3d
```

**Linux** : pour installer [K3d](https://k3d.io/) :

```bash
wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
```

---

* Pour s'assurer que [K3d](https://k3d.io/) est correctement installé, exécuter les deux commandes suivantes :

```bash
k3d version
```

La sortie console attendue :

```bash
k3d version v5.7.5
k3s version v1.30.6-k3s1 (default)
```

Nous allons créer un cluster Kubernetes composé de trois nœuds dont un sera dédié au nœud maître et les deux autres seront dédiés aux nœuds de travail. Sous [K3d](https://k3d.io/), un nœud de travail est intitulé `agent` et un nœud maître est intitulé `server`.

* Créer un cluster Kubernetes via [K3d](https://k3d.io/) qui s'appelera `mycluster` :

```
k3d cluster create mycluster --agents 2 --servers 1
```

Cette commande crée un cluster Kubernetes appelé `mycluster`. Il contient deux nœuds de travail (`--agents 2`) et un (1) nœud maître (`--servers 1`). 

* Consulter les conteneurs [Docker](https://www.docker.com/ "Docker") qui ont été créés :

```bash
docker ps
```

La sortie console attendue :

```bash
CONTAINER ID   IMAGE                            COMMAND                  CREATED          STATUS          PORTS                             NAMES
d704cbb9c45c   ghcr.io/k3d-io/k3d-proxy:5.7.5   "/bin/sh -c nginx-pr…"   33 seconds ago   Up 23 seconds   80/tcp, 0.0.0.0:44741->6443/tcp   k3d-mycluster-serverlb
c0198c7d914d   rancher/k3s:v1.30.6-k3s1         "/bin/k3d-entrypoint…"   40 seconds ago   Up 28 seconds                                     k3d-mycluster-agent-1
a27803a3028f   rancher/k3s:v1.30.6-k3s1         "/bin/k3d-entrypoint…"   40 seconds ago   Up 28 seconds                                     k3d-mycluster-agent-0
7fba4be33563   rancher/k3s:v1.30.6-k3s1         "/bin/k3d-entrypoint…"   40 seconds ago   Up 32 seconds                                     k3d-mycluster-server-0
```

Les deux nœuds de travail sont encapsulés par les deux conteneurs nommés `k3d-mycluster-agent-0` et `k3d-mycluster-agent-1`, le nœud maître est encapsulé par un (1) conteneur nommé `k3d-mycluster-server-0` et un conteneur `k3d-mycluster-serverlb` qui sert d'équilibreur de charge (_LoadBalancer_) pour le cluster K8s.

Pour permettre l'accès au cluster Kubernetes, [K3d](https://k3d.io/) génère un fichier dans _~/.kube/config_. Ce fichier contient des informations, telles que les autorisations nécessaires pour les outils clients, et sert à établir la communication avec le composant API Server du cluster.

Si vous souhaitez récupérer ce fichier, vous pouvez exécuter la commande suivante pour l'obtenir :

```bash
k3d kubeconfig get mycluster > k3s.yaml
```

Nous avons désormais un cluster Kubernetes, mais nous ne disposons pas encore des outils pour interagir avec celui-ci. Nous détaillons ci-après comment installer les outils de gestion **kubectl** et [K9s](https://k9scli.io/) sur votre poste de développeur. Leurs utilisations seront détaillées dans l'exercice suivant.

**kubectl** et [K9s](https://k9scli.io/) sont des outils qui communiquent avec le composant *API Server* et nécessitent d'accéder au fichier *k3s.yaml* obtenu précédemment.

### Installation kubectl 

**kubectl** est un outil en ligne de commande (CLI) qui permet d'interagir avec un cluster Kubernetes via le composant **kube-apiserver**.

---

**macOS** : pour installer **kubectl** via [Homebrew](https://brew.sh/) :

```bash
brew install kubectl
```

**Linux** : pour installer **kubectl** sur n'importe quelle distribution Linux :

```bash
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client
```

---

* Pour tester si **kubectl** est correctement installé :

```bash
kubectl top nodes
```

La sortie console attendue :

```bash
NAME                     CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
k3d-mycluster-agent-0    55m          2%     176Mi           2%
k3d-mycluster-agent-1    78m          3%     235Mi           2%
k3d-mycluster-server-0   101m         5%     426Mi           5%
```

La commande permet d'obtenir des informations sur les ressources utilisées par des objets gérés par Kubernetes (ici l'objet est un nœud).

### Installation K9s

[K9s](https://k9scli.io/) est un gestionnaire de cluster Kubernetes qui a la particularité de fonctionner dans la console. L'interface utilisateur est très simpliste, mais permet de retourner en continu l'état du cluster.

---

**macOS** : pour installer **K9s** via [Homebrew](https://brew.sh/) :

```bash
brew install k9s
```

**Linux** : pour installer **K9s** :

```bash
wget https://github.com/derailed/k9s/releases/download/v0.32.7/k9s_Linux_amd64.tar.gz
tar xzf k9s_Linux_amd64.tar.gz
sudo mv ./k9s /usr/local/bin/k9s
```

---

* Pour tester si **K9s** est correctement installé, depuis un autre terminal :

```bash
k9s
```

Vous devriez obtenir le même résultat que sur la figure ci-dessous.

![Outil K9s affichant les Pods déployés sur le cluster K8s d'une distribution K3d](../images/k9s-k3d.png "K9s pour gérer votre cluster K8s d'une distribution K3d")

## Configurer un registre d'images Docker miroir

L'utilisation de Kubernetes amène à télécharger de nombreuses images [Docker](https://www.docker.com/ "Docker") depuis le dépôt [Docker HUB](https://hub.docker.com/ "Docker HUB"). Le problème est que ce dernier impose une limite à 100 téléchargements d'image [Docker](https://www.docker.com/ "Docker") chaque 6 heures par adresse IP (ou 200 téléchargements pour les utilisateurs authentifiés). Des informations supplémentaires sont disponibles ici : https://docs.docker.com/docker-hub/download-rate-limit/.

Si vous souhaitez connaître l'état de votre consommation, veuillez procéder aux manipulations suivantes.

* Pour obtenir un _token_, en anonyme.

```bash
TOKEN=$(curl "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" | jq -r .token)
```

* Ou pour obtenir un _token_ en mode authentifié.

```bash
TOKEN=$(curl --user 'username:password' "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" | jq -r .token)
```

* Enfin, pour obtenir les informations liées au quota de [Docker HUB](https://hub.docker.com/ "Docker HUB").

```bash
curl --head -H "Authorization: Bearer $TOKEN" https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest
```

La sortie console attendue :

```bash
HTTP/1.1 200 OK
content-length: 2782
content-type: application/vnd.docker.distribution.manifest.v1+prettyjws
docker-content-digest: sha256:767a3815c34823b355bed31760d5fa3daca0aec2ce15b217c9cd83229e0e2020
docker-distribution-api-version: registry/2.0
etag: "sha256:767a3815c34823b355bed31760d5fa3daca0aec2ce15b217c9cd83229e0e2020"
date: Tue, 07 Feb 2023 11:33:38 GMT
strict-transport-security: max-age=31536000
ratelimit-limit: 100;w=21600
ratelimit-remaining: 100;w=21600
docker-ratelimit-source: X.Y.Z.W
```

La limite est fixée par `ratelimit-limit: 100;w=21600` et la consommation par `ratelimit-remaining: 100;w=21600`. 

Pour résoudre le problème de quota au niveau de [Docker HUB](https://hub.docker.com/ "Docker HUB"), vous pouvez soit passer par un abonnement payant soit passer par un miroir d'images [Docker](https://www.docker.com/ "Docker") privé. C'est cette seconde solution que nous allons expliquer dans la suite. Bien entendu il vous conviendra de fournir un miroir d'images [Docker](https://www.docker.com/ "Docker") privé, nous montrerons simplement comment configurer un cluster [K3d](https://k3d.io/) avec un miroir d'images [Docker](https://www.docker.com/ "Docker") privé.

* Créer un fichier de configuration appelé _registries.yaml_ avec le contenu suivant.

```yaml
mirrors:
  "docker.io":
    endpoint:
      - https://URL_YOUR_REGISTRY
```

* La configuration du miroir d'images [Docker](https://www.docker.com/ "Docker") privé se fait lors de la création du cluster [K3d](https://k3d.io/).

```bash
k3d cluster create mycluster --agents 2 --servers 1 --registry-config "$(pwd)/registries.yaml"
```

## Bilan de l'exercice

À cette étape, vous disposez :

* d'un cluster Kubernetes avec trois nœuds dont un pour le maître et deux autres pour les nœuds de travail ;
* de deux outils de contrôle pour notre cluster Kubernetes.

## Ressources

* https://betterprogramming.pub/local-k3s-cluster-made-easy-with-multipass-108bf6ce577c
* https://k33g.gitlab.io/articles/2020-02-21-K3S-01-CLUSTER.html