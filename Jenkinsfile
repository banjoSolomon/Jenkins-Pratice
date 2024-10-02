pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials' // Jenkins credentials ID for Docker Hub
        DOCKER_IMAGE_NAME = 'solomon11/jenks' // Name of your Docker image
        DOCKER_IMAGE_TAG = '2' // Tag for your Docker image
    }

    stages {
        stage('Clone Repository') {
            steps {
                git 'https://github.com/banjoSolomon/Jenkins-Pratice.git'
            }
        }

        stage('Set Up Docker Buildx') {
            steps {
                script {
                    // Create and set up Docker Buildx builder
                    sh 'docker buildx create --use'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build the Docker image using Buildx
                    sh "docker buildx build --platform linux/amd64,linux/arm64 -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} . --push"
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    script {
                        // Log in to Docker Hub
                        sh "echo \$DOCKER_PASSWORD | docker login -u \$DOCKER_USERNAME --password-stdin"

                        // Push the Docker image to Docker Hub (this is now handled in the build stage with --push)
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs() // Clean workspace after the build
        }
    }
}
