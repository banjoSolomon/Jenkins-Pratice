pipeline {
    agent any

    environment {
        // Store Docker Hub credentials securely
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
    }

    stages {
        stage('Checkout code') {
            steps {
                // Checkout the source code from the SCM
                checkout scm
            }
        }

        stage('Set up JDK 17') {
            steps {
                // Wrap steps in a node block
                script {
                    node {
                        // Install OpenJDK 17
                        sh 'sudo apt-get update'
                        sh 'sudo apt-get install openjdk-17-jdk -y'
                        sh 'java -version' // Verify the installation
                    }
                }
            }
        }

        stage('Restore Maven Package') {
            steps {
                // Wrap steps in a node block
                script {
                    node {
                        // Restore Maven dependencies
                        sh 'mvn dependency:go-offline'
                    }
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                script {
                    // Wrap steps in a node block
                    node {
                        // Login to Docker Hub
                        docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS) {
                            echo 'Logged into Docker Hub'
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Wrap steps in a node block
                    node {
                        // Build the Docker image with the specified name
                        docker.build("solomon11/jenk:latest")
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    // Wrap steps in a node block
                    node {
                        // Push the built Docker image to Docker Hub
                        docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS) {
                            def image = docker.image("solomon11/jenk:latest")
                            image.push() // Push the image with the latest tag
                        }
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
