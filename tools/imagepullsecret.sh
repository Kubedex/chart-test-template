#!/bin/sh
kubectl create ns $1
kubectl -n $1 create secret docker-registry aws-registry \
      --docker-server=https://$2.dkr.ecr.$3.amazonaws.com \
      --docker-username=AWS \
      --docker-password=$4 \
      --docker-email=no@email.local
