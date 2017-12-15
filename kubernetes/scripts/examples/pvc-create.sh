NAME=$1

echo "kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: ${NAME}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi
  storageClassName: scaleio" | kubectl create -f -
