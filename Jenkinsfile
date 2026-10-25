pipeline {
    agent { label 'docker' }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        K8S_HOST = 'REPLACE_WITH_K8S_NODE_PUBLIC_IP'
        LOCAL_IMAGE = "prt-cicd:${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Build Docker image') {
            steps { sh 'docker build --pull -t "$LOCAL_IMAGE" .' }
        }

        stage('Smoke test') {
            steps {
                sh '''set -eu
                docker rm -f prt-ci-smoke >/dev/null 2>&1 || true
                docker run -d --name prt-ci-smoke -p 18080:80 "$LOCAL_IMAGE"
                trap 'docker rm -f prt-ci-smoke >/dev/null 2>&1 || true' EXIT
                sleep 3
                curl --fail --silent http://127.0.0.1:18080/ | grep -F 'CI/CD Completed Successfully'
                '''
            }
        }

        stage('Push image to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_TOKEN')]) {
                    sh '''set -eu
                    IMAGE="$DOCKERHUB_USER/prt-cicd:$BUILD_NUMBER"
                    echo "$DOCKERHUB_TOKEN" | docker login --username "$DOCKERHUB_USER" --password-stdin
                    docker tag "$LOCAL_IMAGE" "$IMAGE"
                    docker tag "$LOCAL_IMAGE" "$DOCKERHUB_USER/prt-cicd:latest"
                    docker push "$IMAGE"
                    docker push "$DOCKERHUB_USER/prt-cicd:latest"
                    docker logout
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'k8s-ssh', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')
                ]) {
                    sh '''set -eu
                    IMAGE="$DOCKERHUB_USER/prt-cicd:$BUILD_NUMBER"
                    sed "s|IMAGE_PLACEHOLDER|$IMAGE|g" k8s/deployment.yaml |
                      ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SSH_USER@$K8S_HOST" 'kubectl apply -f -'
                    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SSH_USER@$K8S_HOST" 'kubectl apply -f -' < k8s/service.yaml
                    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SSH_USER@$K8S_HOST" 'kubectl rollout status deployment/prt-cicd --timeout=180s && kubectl get pods,svc'
                    '''
                }
            }
        }
    }

    post {
        success { echo 'PRT – CI/CD Completed Successfully' }
        always { echo 'Pipeline run finished; review the stage view and console log.' }
    }
}
