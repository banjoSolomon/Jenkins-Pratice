pipeline {
    agent any

    environment {
        DOCKER_IMAGE_NAME = 'jenks' // Replace with your Docker image name
        DOCKER_HUB_REPO = 'solomon11/${DOCKER_IMAGE_NAME}' // Replace with your Docker Hub username
    }

    stages {
        stage('Checkout') {
            steps {
                // Checkout the source code from the repository
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Use credentials for Docker Hub
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        // Build the Docker image
                        sh "docker build -t ${DOCKER_HUB_REPO}:${env.BUILD_ID} ."

                        // Login to Docker Hub
                        sh "echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin"

                        // Push the Docker image to Docker Hub
                        sh "docker push ${DOCKER_HUB_REPO}:${env.BUILD_ID}"
                    }
                }
            }
        }
    }

    post {
        always {
            // Clean up the workspace after the build
            cleanWs()
        }
    }
}
