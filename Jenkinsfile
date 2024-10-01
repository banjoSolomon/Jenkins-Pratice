pipeline {
    agent any

    tools {
        // Use the configured Maven version in Jenkins (Make sure Maven 3.6.3 is installed in Jenkins under Global Tool Configuration)
        maven 'Maven 3.6.3'
    }

    environment {
        // Replace with your Docker Hub username and image name
        DOCKER_IMAGE = "solomon11/jenk"
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
    }

    stages {
        stage('Checkout') {
            steps {
                // Checkout the source code from the Git repository
                git 'https://github.com/banjoSolomon/Jenkins-Pratice'
            }
        }

        stage('Build with Maven') {
            steps {
                // Use Maven to clean and install the project dependencies and build the project
                sh 'mvn clean install'
            }
        }

        stage('Login to Docker Hub') {
            steps {
                script {
                    // Log in to Docker Hub with stored credentials
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS) {
                        echo 'Logged into Docker Hub'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build the Docker image and tag it as 'latest'
                    def image = docker.build("${DOCKER_IMAGE}:latest")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    // Push the Docker image to Docker Hub
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS) {
                        def image = docker.image("${DOCKER_IMAGE}:latest")
                        image.push('latest')  // Push the image with the 'latest' tag
                    }
                }
            }
        }
    }

    post {
        always {
            // Make sure to perform clean up within a node context
            script {
                cleanWs()  // This ensures the workspace is cleaned up properly
            }
        }
    }
}