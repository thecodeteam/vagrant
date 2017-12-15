#!/bin/bash
kubectl delete pod $(kubectl get pods | grep mongodb | awk '{print $1}')
