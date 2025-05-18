export KOPS_STATE_STORE=s3://prabhas.flm.k8s
kops delete cluster --name govardhan.k8s.local --yes
aws s3 rb s3://prabhas.flm.k8s --force
