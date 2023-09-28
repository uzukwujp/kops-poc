NAME="john.k8s.local"

export KOPS_STATE_STORE=s3://example-state-store

kops create -f cluster.yaml

kops create secret --name $NAME sshpublickey admin -i ~/.ssh/id_rsa.pub

kops update cluster --name $NAME -f cluster.yaml --yes

# validate that cluster is running
kops validate cluster --wait 10m


# updating a cluster after making a change in the cluster spec file

# kops replace -f cluster.yaml
# kops update cluster $NAME --yes
# kops rolling-update cluster $NAME --yes


# delete a cluster

# kops delete -f cluster.yaml --yes


# export kubeconfig file

# kops export kubeconfig --admin



