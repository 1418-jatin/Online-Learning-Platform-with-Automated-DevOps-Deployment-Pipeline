pipeline {
    agent any

    environment {
        DOCKERHUB_CRED = credentials('dockerhub-cred')
        IMAGE_NAME = "19901418/prt-oct-25th"
        IMAGE_TAG = "latest"
    }

    stages {
        stage('Checkout SCM') {
            steps { checkout scm }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build --no-cache -t $IMAGE_NAME:$IMAGE_TAG ."
            }
        }

        stage('Push Docker Image') {
            steps {
                sh '''
                echo $DOCKERHUB_CRED_PSW | docker login -u $DOCKERHUB_CRED_USR --password-stdin
                docker push $IMAGE_NAME:$IMAGE_TAG
                '''
            }
        }

        stage('Deploy to Application Servers') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ubuntu-cred', keyFileVariable: 'SSH_KEY')]) {
                    sh '''
                    for HOST in 3.142.241.187 3.148.215.92; do
                        ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@$HOST "
                            docker pull $IMAGE_NAME:$IMAGE_TAG &&
                            (docker stop prt-app || true) &&
                            (docker rm prt-app || true) &&
                            docker run -d --name prt-app -p 8000:80 $IMAGE_NAME:$IMAGE_TAG
                        "
                    done
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ubuntu-cred', keyFileVariable: 'SSH_KEY')]) {
                    sh '''
                    for HOST in 3.142.241.187 3.148.215.92; do
                        ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@$HOST "
                            docker ps | grep prt-app || true
                        "
                    done
                    '''
                }
            }
        }
    }

    post {
        always { sh 'docker logout' }
    }
}
