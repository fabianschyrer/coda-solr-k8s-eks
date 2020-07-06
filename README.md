SolrCloud Zookeeper Kubernetes
==============================

# Introduction

This project aims to help developers and newbies that would try latest version of SolrCloud (and Zookeeper) in a Kubernetes environment.

Here you'll find basically two different configuration:

* one (or more) Solr instance and one Zookeeper configured as Standalone node
* one (or more) Solr instance and a Zookeeper Ensemble (which means a cluster)

The Zookeeper configuration (and interaction with Solr) is the hardest part of the project.
It is important to point out that Zookeeper has two different configuration: Standalone and Ensemble.

* Standalone has only one node
* Ensemble is a cluster and has always an odd number of nodes starting from 3 (i.e. 3, 5, 7, etc.).  

Here we need two different configuration (StatefulSet) for Zookeeper, depending if you want have Standalone or Ensemble. Of course if you need to deploy an high availablity configuration, there are no ways, you can't have a single point of failure so you need to start an Ensemble.

Solr on the other hand can run one or more instances transparentely from the zookeeper configuration, it just need to have one or more Zookeeper correctly configured and running a version compatible with the Sor version you choose.

# Kubernetes Deployment Envs

* Amazon Elastic Kubernetes Service (EKS)


At end of installation Solr (port 8983) and Zookeeper (port 2181) are reachable via kubernetes services that acts as TCP [LoadBalancer](https://kubernetes.io/docs/concepts/services-networking/#loadbalancer).

Note: Use CloudSolrClient in your Java client application only inside the Kubernetes Cluster, from outside better if you use HttpSolrClient via the loadbalancer.

## Quick start

If you want try a light configuration with 1 SolrCloud container and 1 Zookeeper container, start with:

    git clone https://github.com/fabianschyrer/coda-solr-k8s-eks.git
    cd solrcloud-zookeeper-kubernetes

## Amazon Elastic Kubernetes Service (Amazon EKS) quickstart

* You need a Kubernetes Cluster - [Creating an Amazon EKS Cluster](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html)

<pre><code>    $ eksctl create cluster \
    --name solr \
    --version 1.16 \
    --region ap-southeast-1 \
    --nodegroup-name standard-workers \
    --node-type t3.medium \
    --nodes 4 \
    --node-ami auto \
    --nodes-min 1 \
    --nodes-max 4 \
    --managed
</code></pre>

Now you can start your cluster:

    start.sh

To find the services load balancer just run:

    $ kubectl get services
    NAME           TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)          AGE
    kubernetes     ClusterIP      10.100.0.1       <none>                                                                   443/TCP          13m
    solr-service   LoadBalancer   10.100.115.145   a50c0fe32b57211e9a3fc0ae1e2f29a2-134001589.eu-west-1.elb.amazonaws.com   8983:30107/TCP   107s
    solrcluster    ClusterIP      None             <none>                                                                   <none>           107s
    zk-service     LoadBalancer   10.100.134.160   a502a5087b57211e9a3fc0ae1e2f29a2-301817188.eu-west-1.elb.amazonaws.com   2181:32609/TCP   108s
    zkensemble     ClusterIP      None             <none>                                                                   <none>           108s

## Shutdown

If you want shutdown Solr and Zookeeper just run:

    ./stop.sh

## Looking at the logs

    kubectl exec -t -i zk-0 -- tail -100f /store/logs/zookeeper.log

### Introduction to Stateful application in Kubernetes

Before to deploy Solr or Zookeeper in Kubernetes, it is important understand what's the difference between Stateless and Stateful applications in Kubernetes.

> Stateless applications
>
> A stateless application does not preserve its state and saves no data to persistent storage — all user and session data stays with the client.
>
> Some examples of stateless applications include web frontends like Nginx, web servers like Apache Tomcat, and other web applications.
>
> You can create a Kubernetes Deployment to deploy a stateless application on your cluster. Pods created by Deployments are not unique and do not preserve their state, which makes scaling and updating stateless applications easier.
>
> Stateful applications
>
>A stateful application requires that its state be saved or persistent. Stateful applications use persistent storage, such as persistent volumes, to save data for use by the server or by other users.
>
>Examples of stateful applications include databases like MongoDB and message queues like Apache ZooKeeper.
>
>You can create a Kubernetes StatefulSet to deploy a stateful application. Pods created by StatefulSets have unique identifiers and can be updated in an ordered, safe way.

So a Solrcloud Cluster matches exactly the kind of Stateful application previously described.
And we have to create the environment following these steps:

1. create configmap where store the cluster configuration
2. create statefulsets for Solr and Zookeeper that can write their data on persistent volumes
3. map solr and zookeeper as network services (loadbalancer or nodeport)
