#!/bin/bash

kubectl create configmap solr-config --from-env-file=configmap/solr-cluster-config.properties
# kubectl create configmap zookeeper-config --from-env-file=configmap/zookeeper-config.properties
kubectl create configmap zookeeper-config --from-env-file=configmap/zookeeper-ensemble-config.properties

kubectl create -f statefulsets/statefulset-zookeeper.yml
#kubectl create -f statefulsets/statefulset-zookeeper-ensemble.yml
kubectl create -f services/service-zookeeper-ensemble.yml

sleep 30

#kubectl create -f statefulsets/statefulset-solr.yml
kubectl create -f statefulsets/statefulset-solr-cluster.yml
kubectl create -f services/service-solr-cluster.yml

kubectl get pod

kubectl get deployment

kubectl get service
