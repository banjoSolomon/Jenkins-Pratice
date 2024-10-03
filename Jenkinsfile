pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials' // Jenkins credentials ID for Docker Hub
        DOCKER_IMAGE_NAME = 'solomon11/jenkins' // Docker image name
        DOCKER_IMAGE_TAG = 'latest' // Docker image tag
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'in-dev', url: 'https://github.com/banjoSolomon/Jenkins-Pratice.git'
            }
        }

        stage('Set Up Docker Buildx') {
            steps {
                script {
                    // Create and use Docker Buildx builder if it doesn't exist
                    sh 'docker buildx create --use || true'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Log in to Docker Hub before building and pushing
                    withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        // Log in to Docker Hub
                        sh "echo \$DOCKER_PASSWORD | docker login -u \$DOCKER_USERNAME --password-stdin"
                    }
                    // Build the Docker image for multiple platforms and push
                    sh "docker buildx build --platform linux/amd64,linux/arm64 -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} . --push"
                }
            }
        }
    }

    post {
        always {
            cleanWs() // Clean up the workspace after the build
        }
    }
}
