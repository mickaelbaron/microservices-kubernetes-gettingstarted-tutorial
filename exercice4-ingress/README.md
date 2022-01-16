# Exercice 4 : communiquer avec les Pods via des règles de routage

Dans l'exercice précédent, nous avons étudié les `Services` via les objets `ClusterIP` et `NodePort`. Nous avons montré que le `Service` `ClusterIP` ne permettait pas d'accéder aux `Pods` depuis l'extérieur du cluster et que le `Service` `NodePort` nécessitait de réserver un port réseau sur tout le cluster même si aucun `Pod` ne tournait. Il existe également un autre type de `Service` appelait `LoadBalancer` qui est difficilement configurable pour un cluster qui n'est pas dans le Cloud (notre cas actuellement).

Nous présentons dans cet exercice les `Ingress`, une solution qui s'appuie sur les `Services`. Un `Ingress` est une règle qui relie une URL à un objet `Service`. Par ailleurs, un `Ingress` utilise un contrôleur `Ingress` pour piloter un `Reverse Proxy` pour implémenter les règles. **Toutefois, un `Ingress` n'est pas un objet de type `Service`**. L'objectif visé par un `Ingress` est d'éviter d'utiliser un `Service` de type `NodePort` ou `LoadBalancer` pour communiquer depuis l'extérieur d'un cluster Kubernetes, seul un `Service` de type `ClusterIP` sera suffisant.

> Quelque soit le type d'installation choisi pour la mise en place de votre cluster Kubernetes, toutes les commandes ci-dessous devraient normalement fonctionner. Nous considérons qu'il existe un fichier `k3s.yaml` à la racine du dossier `microservices-kubernetes-gettingstarted-tutorial/`, si ce n'est pas le cas, merci de reprendre la mise en place d'un cluster Kubernetes. Il est important ensuite de s'assurer que la variable `KUBECONFIG` soit initialisée avec le chemin du fichier d'accès au cluster Kubernetes (`export KUBECONFIG=$PWD/k3s.yaml`).

## But

* Écrire une configuration `Ingress` ;
* Gérer des hôtes virtuels.

## Étapes à suivre

* Avant de commencer les étapes de cet exercice, assurez-vous que le `Namespace` créé dans l'exercice précédent `mynamespaceexercice3` soit supprimé. Si ce n'est pas le cas :

```
$ kubectl delete namespace mynamespaceexercice3
namespace "mynamespaceexercice3" deleted
```

* Créer dans le répertoire _exercice4-ingress/_ un fichier appelé mynamespaceexercice4.yaml_ en ajoutant le contenu suivant :

```
apiVersion: v1
kind: Namespace
metadata:
  name: mynamespaceexercice4
```

* Créer ce `Namespace` dans notre cluster :

```
$ kubectl apply namespace exercice4-ingress/mynamespaceexercice4.yaml
namespace/mynamespaceexercice4 created
```

Dans les étapes suivantes, nous allons créer deux `Deployments` afin de simuler l'existence de deux applications différentes (microservices). Les deux `Deployment` seront basés sur la même image [Docker](https://www.docker.com/ "Docker") [Nginx](https://www.nginx.com/) pour déployer des `Pods`. Pour différencier les deux applications, nous modifierons la page _index.html_ de chaque conteneur afin d'identifier clairement l'application visée par nos requêtes. Pour accéder à ces applications (microservices) depuis l'extérieur du cluster, nous utiliserons un `Ingress` avec deux règles afin de pouvoir accéder aux deux applications via les URL suivantes : http://<IP_NODE>/app1 pour la première application et http://<IP_NODE>/app2 pour la seconde application. Cette forme de configuration est appelée `fanout` et permet de définir une règle à base de sous-chemins.

* Créer dans le répertoire _exercice4-ingress/_ un fichier appelé _app1deployment.yaml_ qui décrit un `Deployment` et un `Service` `ClusterIP` pour la première application :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app1pod
  template:
    metadata:
      labels:
        app: app1pod
    spec:
      containers:
      - name: app1container
        image: nginx:latest
        ports:
        - containerPort: 80
        lifecycle:
          postStart:
            exec:
              command: 
                - /bin/sh
                - -c
                - >
                  mkdir /usr/share/nginx/html/app1;
                  echo App 1 from $HOSTNAME > /usr/share/nginx/html/app1/index.html

---

apiVersion: v1
kind: Service
metadata:
  name: app1service
spec:
  selector:
    app: app1pod
  type: ClusterIP
  ports:
    - protocol: TCP
      targetPort: 80
      port: 8080
```

Vous noterez dans la partie `command` la création du répertoire _app1_. Cela est nécessaire pour que la requête puisse aboutir, problématique courante quand il est nécessaire de déployer avec des sous-chemins.

* Créer dans le répertoire _exercice4-ingress/_ un fichier appelé _app1deployment.yaml_ qui décrit un `Deployment` et un `Service` `ClusterIP` pour la seconde application :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app2pod
  template:
    metadata:
      labels:
        app: app2pod
    spec:
      containers:
      - name: app2container
        image: nginx:latest
        ports:
        - containerPort: 80
        lifecycle:
          postStart:
            exec:
              command: 
                - /bin/sh
                - -c
                - >
                  mkdir /usr/share/nginx/html/app2;
                  echo App 2 from $HOSTNAME > /usr/share/nginx/html/app2/index.html

---

apiVersion: v1
kind: Service
metadata:
  name: app2service
spec:
  selector:
    app: app2pod
  type: ClusterIP
  ports:
    - protocol: TCP
      targetPort: 80
      port: 8080
```

* Appliquer les deux configurations précédente pour créer les `Deployments` et les `Services` dans le cluster Kubernetes :

```
$ kubectl apply -f exercice4-ingress/app1deployment.yaml -n mynamespaceexercice4
deployment.apps/app1deployment created
service/app1service created
$ kubectl apply -f exercice4-ingress/app2deployment.yaml -n mynamespaceexercice4
deployment.apps/app2deployment created
service/app2service created
```

* Créer dans le répertoire _exercice4-ingress/_ un fichier appelé _myingress.yaml_ qui décrit un `Ingress` :

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myingress
spec:
  rules:
    - http:
        paths:
        - path: /app1
          pathType: Prefix
          backend:
            service:
              name: app1service
              port:
                number: 8080
        - path: /app2
          pathType: Prefix
          backend:
            service:
              name: app2service
              port:
                number: 8080

```

Deux règles sont définies. La première traite du chemin (`path`) `/app1` et s'applique au `Service` `app1service` et la seconde traite du chemin (`path`) `/app2` et s'applique au `Service` `app2service`. 

* Appliquer cette configuration pour créer cet `Ingress` dans le cluster Kubernetes :

```
$ kubectl apply -f exercice4-ingress/myingress.yaml -n mynamespaceexercice4
ingress.networking.k8s.io/myingress created
```

* Afficher le détail complet de cet `Ingress` via l'option `describe` pour s'assurer que tout est configuré correctement :

```
$ kubectl describe ingress -n mynamespaceexercice4 myingress
Name:             myingress
Namespace:        mynamespaceexercice4
Address:          192.168.64.10,192.168.64.11,192.168.64.9
Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /app1   app1service:8080 (10.42.0.83:80,10.42.2.68:80)
              /app2   app2service:8080 (10.42.1.67:80,10.42.2.71:80)
Annotations:  <none>
Events:       <none>
```

* Il ne reste plus qu'à tester les deux règles, en utilisant l'outil **cURL** :

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
$ curl 192.168.64.9/app1/
App 1 from app1deployment-95f49fb56-d5pj5
$ curl 192.168.64.10/app2/
App 2 from app2deployment-567484c687-tbvxv
```

Les `Ingress` permettent également de gérer les hôtes virtuels pour éviter d'utiliser les sous-chemins (`fanout`). Ainsi, au lieu d'utiliser cette forme d'URL http://<IP_NODE>/app1 nous allons plutôt utiliser celle-ci http://app1.mydomain.test. Toutefois, puisque nous ne disposns pas du domaine http://mydomain.test nous allons devoir configurer le poste du développeur pour configurer.

** macOS

** Linux


## Bilan de l'exercice

À cette étape, vous savez :

* créer des `Ingress` ;
* créer des règles de type `fanout` ou hôtes virtuels ; 
* configuration son poste de développeur pour répondre à des hôtes virtuels.

## Avez-vous bien compris ?

Pour continuer sur les concepts présentés dans cet exercice, nous proposons de continuer avec les manipulations suivantes :

* TODO
* TODO

## Ressources

