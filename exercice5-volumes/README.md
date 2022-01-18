# Exercice 5 : conserver les données

Les données des `Pods` sont volatibles, c'est-à-dire qu'à chaque destruction d'un `Pod` toutes les données qui ont pu être générées seront perdues. Les types données qui sont gérés par un `Pod` peuvent être des données applicatives (base de données), des logs, des fichiers de configuration, des fichiers de partage, etc. Nous adressons la problématique suivante dans cet exercice : comment s'assurer que si un `Pod` est recréé, les données précédentes soient restaurées. Pour y répondre, nous introduisons le concept de `Volume`. Un `Volume` représente un espace de stockage contenant des données et accessible à travers plusieurs conteneurs d'un même `Pod`ou de `Pods` différents. Différents types de `Volume` existent selon le besoin de stockage à gérer. Nous étudierons les `Volumes` de type `hostPath` et `emptyDir` pour l'accès à des stockages sur un même nœud puis `gitRepo` pour des `Volumes` basés sur des dossiers réseaux. 

> Quelque soit le type d'installation choisi pour la mise en place de votre cluster Kubernetes, toutes les commandes ci-dessous devraient normalement fonctionner. Nous considérons qu'il existe un fichier `k3s.yaml` à la racine du dossier `microservices-kubernetes-gettingstarted-tutorial/`, si ce n'est pas le cas, merci de reprendre la mise en place d'un cluster Kubernetes. Il est important ensuite de s'assurer que la variable `KUBECONFIG` soit initialisée avec le chemin du fichier d'accès au cluster Kubernetes (`export KUBECONFIG=$PWD/k3s.yaml`).

## But

* TODO
* TODO
* TODO

## Étapes à suivre

* Avant de commencer les étapes de cet exercice, assurez-vous que le `Namespace` créé dans l'exercice précédent `mynamespaceexercice4` soit supprimé. Si ce n'est pas le cas :

```
$ kubectl delete namespace mynamespaceexercice4
namespace "mynamespaceexercice4" deleted
```

* Créer dans le répertoire _exercice5-volumes/_ un fichier appelé mynamespaceexercice5.yaml_ en ajoutant le contenu suivant :

```
apiVersion: v1
kind: Namespace
metadata:
  name: mynamespaceexercice5
```

* Créer ce `Namespace` dans notre cluster :

```
$ kubectl apply namespace exercice5-volumes/mynamespaceexercice5.yaml
namespace/mynamespaceexercice5 created
```

Nous commençons par le `Volume` de type `hostPath` qui permet de monter une ressource (dossier ou un fichier) depuis le système de fichiers du nœud hôte du `Pod`. Les cas d'usage courants sont l'accès aux éléments internes du nœud (_/var/lib/dock_ ou _/sys_) dans le cas où vous souhaitez faire du [Docker](https://www.docker.com/ "Docker") dans [Docker](https://www.docker.com/ "Docker") ou l'accès à un répertoire distant monté sur les systèmes hôtes de tous les nœuds. Toutefois, certaines précautions doivent être prises pour l'utilisation de ce type de `Volume`. La première est la difficulté d'utiliser un `Volume` de type `hostPath` sur un environnement multi-nœuds et la seconde est qu'il n'est pas possible de choisir le nœud d'un `Pod`. 

* Créer dans le répertoire _exercice5-volumes/_ un fichier appelé _myhostpath.yaml_ qui décrit un `Deployment`, un `Service` `NodePort` et un `Volume` de type `hostPath` :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mydeploymentwithhostpath
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mypodforhostpath
  template:
    metadata:
      labels:
        app: mypodforhostpath
    spec:
      containers:
      - name: mynginx
        image: nginx:latest
        ports:
        - containerPort: 80 
        volumeMounts:
          - mountPath: /usr/share/nginx/html
            name: myhostpathvolume
      volumes:
        - name: myhostpathvolume
          hostPath:
            path: /myhostpath
            type: DirectoryOrCreate

---

kind: Service
apiVersion: v1
metadata:
  name: mynodeportservice
spec:
  selector:
    app: mypodforhostpath
  type: NodePort
  ports:
    - protocol: TCP
      targetPort: 80
      port: 8080
      nodePort: 30001
```

Le `Volume` est déclaré dans la partie `volumes` où il est identifié par un nom `myhostpathvolume`. Le type de `Volume` est ensuite précisé puis suivent des paramètres spécifiques à `hostPath`. Le paramètre `path` détaille le répertoire sur le système de fichiers où seront stockés les ressources à partager. Le paramètre `type` définit une stratégie de création du répertoire qui pour `DirectoryOrCreate` forcera la création du répertoire _myhostpath_ si celui-ci n'existe pas. La partie `volumeMounts` configure le `Volume` du côté du conteneur. Le paramètre `mountPath` détaille le chemin où ce `Volume` sera accessible depuis le `Pod`. Dans cet exemple, le répertoire (_/usr/share/nginx/html_) qui contient la page web par défaut de [Nginx](https://www.nginx.com/) est monté avec le dossier _/myhostpath_ qui se trouve sur le nœud hôte du `Pod`. Vous remarquerez que trois `Pods` ont été créés (`replicas: 3`), mais cela ne veut pas forcément dire que trois nœuds sont utilisés.

* Appliquer la configuration précédente pour créer le `Deployments` et le `Services` dans le cluster Kubernetes :

```
$ kubectl apply -f myhostpath.yaml -n mynamespaceexercice5
deployment.apps/mydeploymentwithhostpath created
service/mynodeportservice created
```

* Examiner sur quel nœud les `Pods` sont déployés :

```
$ kubectl get Pods -n mynamespaceexercice5 -o wide
NAME                                        READY   STATUS    RESTARTS   AGE   IP           NODE               
mydeploymentwithhostpath-685cc77c87-622g2   1/1     Running   0          99m   10.42.2.75   k8s-workernode-2   
mydeploymentwithhostpath-685cc77c87-7t6dv   1/1     Running   0          99m   10.42.1.72   k8s-workernode-1   
mydeploymentwithhostpath-685cc77c87-hzg4h   1/1     Running   0          98m   10.42.0.84   k8s-master         
```

Kubernetes utilise les trois nœuds pour déployer les trois `Pods`. Puisque la stratégie de création du répertoire est `DirectoryOrCreate`, un répertoire _/myhostpath_ devrait exister sur les trois nœuds.

* Lister le contenu du système de fichiers de chaque nœud :

```
$ multipass exec $master_name -- ls /
bin  boot  dev	etc  home  lib	lib32  lib64  libx32  lost+found  media  mnt  myhostpath  opt  proc  root  run	sbin  snap  srv  sys  tmp  usr	var

$ multipass exec $workernode1_name -- ls /
bin  boot  dev	etc  home  lib	lib32  lib64  libx32  lost+found  media  mnt  myhostpath  opt  proc  root  run	sbin  snap  srv  sys  tmp  usr	var

$ multipass exec $workernode2_name -- ls /
bin  boot  dev	etc  home  lib	lib32  lib64  libx32  lost+found  media  mnt  myhostpath  opt  proc  root  run	sbin  snap  srv  sys  tmp  usr	var

$ multipass exec $workernode2_name -- ls /myhostpath
```

Le dossier _/myhostpath_  est existant sur les trois nœuds, mais son contenu est vide et cela se confirme quand nous effectuons une requête pour récupérer la page web.

* Exécuter la requête suivante :

```
$ curl workernode1_ip:30001
```

* Ajouter un fichier dans le dossier myhostpath

* Vérifier que le fichier existe

* emptyDir, un conteneur qui génère une page

* gitRepo, un site statique

## Bilan de l'exercice

À cette étape, vous savez :

* TODO
* TODO

## Avez-vous bien compris ?

Pour continuer sur les concepts présentés dans cet exercice, nous proposons de continuer avec les manipulations suivantes :

* TODO
* TODO

Bien sur notre étude ne peut être exhaustive puisqu'il y a de nombreux autres type de `Volume` à étudier. kubernetes.io/docs/concepts/storage/volumes

## Ressources

* TODO