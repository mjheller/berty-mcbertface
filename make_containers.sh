#!/usr/bin/env bash

##Following commands to execute in Google Console

# Create Tensorflow Serving Container and host on Dockerhub
IMAGE_NAME=tf_serving_bert_cola_news
VER=1563578991_v1
MODEL_NAME=bert
DOCKER_USER=p0seid0n
cd ~
docker run -d --name $IMAGE_NAME tensorflow/serving
mkdir ~/models
gsutil cp -r  gs://bert-finetuning-cola-news/bert/export/COLA/1563578991 ~/models
#gsutil cp -r gs://thunderbert2/bert-finetuning-cola-news/bert/export/COLA/1563578991 ~/models
docker cp ~/models/1563578991/ $IMAGE_NAME:/models/$MODEL_NAME
docker commit --change "ENV MODEL_NAME $MODEL_NAME" $IMAGE_NAME $USER/$IMAGE_NAME
docker tag $USER/$IMAGE_NAME $DOCKER_USER/$IMAGE_NAME:$VER
docker push $DOCKER_USER/$IMAGE_NAME:$VER

# Create client to call Bert Model
git clone https://github.com/mjheller/berty-mcbertface.git
cd ~/berty-mcbertface

CLIENT_IMAGE_NAME=bert_cola_news_client
CLIENT_VER=v1
DOCKER_USER=p0seid0n
mkdir asset
gsutil cp gs://cloud-tpu-checkpoints/bert/uncased_L-12_H-768_A-12/vocab.txt asset/
docker build -t $USER/$CLIENT_IMAGE_NAME .
docker tag $USER/$CLIENT_IMAGE_NAME $DOCKER_USER/$CLIENT_IMAGE_NAME:$CLIENT_VER
docker push $DOCKER_USER/$CLIENT_IMAGE_NAME:$CLIENT_VER


# run locally install gcloud and kompose
gcloud container clusters create bert-cluster --zone us-east1-b
gcloud config set container/cluster bert-cluster
gcloud container clusters get-credentials bert-cluster --zone us-east1-b

#install kompose if not installed
curl -L https://github.com/kubernetes/kompose/releases/download/v1.18.0/kompose-linux-amd64 -o kompose
chmod +x kompose
sudo mv ./kompose /usr/local/bin/kompose
#convert docker-compose to kubernetes deployment
kompose convert --stdout | kubectl apply -f -
kubectl get service # get service IPs

#wget http://34.73.232.214:8501/v1/models/bert
#wget http://host:port/v1/models/${MODEL_NAME}[/versions/${MODEL_VERSION}]

# to run container
# docker run -p 8500:8500 -p 8501:8501 -it p0seidon/$IMAGE_NAME:$VER -- sh
#docker run -p 8500:8500 -p 8501:8501 -e MODEL_NAME=bert -e MODEL_BASE_PATH=/models/ -it p0seid0n/tf_serving_bert_cola_news:1563578991_v1 -- sh
