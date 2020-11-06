#!/usr/bin/env bash

export APP_NAME=studio
export PROJECT_ID=${GCLOUD_PROJECT}

cd $(dirname $0)/..
root_dir=$(pwd)
cd $root_dir

rm -rf $root_dir/build
rm -rf $root_dir/dist

echo "VUE_APP_GIT_HASH=${GITHUB_SHA}" >> $root_dir/.env.production

npm install && npm run build

mkdir -p ${root_dir}/build/public
cp $root_dir/deploy/nginx-buildpack-config/* ${root_dir}/build
cp -r $root_dir/dist/* ${root_dir}/build/public
cd $root_dir/build

pack build $APP_NAME --builder  paketobuildpacks/builder:full --buildpack gcr.io/paketo-buildpacks/nginx:latest  --env PORT=8080
image_id=$(docker images -q $APP_NAME)
docker tag "${image_id}" gcr.io/${PROJECT_ID}/${APP_NAME}
docker push gcr.io/${PROJECT_ID}/${APP_NAME}

kubectl delete -f ${root_dir}/deploy/deployment.yaml
kubectl apply -f ${root_dir}/deploy/deployment.yaml
kubectl get service $APP_NAME | grep $APP_NAME || kubectl apply -f ${root_dir}/deploy/deployment-service.yaml
