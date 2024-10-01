pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
    }

    stages {
        stage('Checkout code') {
            steps {
                checkout scm
            }
        }

        stage('Set up JDK 17') {
            steps {
                sh 'sudo apt-get update'
                sh 'sudo apt-get install openjdk-17-jdk -y'
                sh 'java -version'
            }
        }

        stage('Restore Maven Package') {
            steps {
                sh 'mvn dependency:go-offline'
            }
        }

        stage('Login to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS) {
                        echo 'Logged into Docker Hub'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("solomon11/jenk:latest")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS) {
                        def image = docker.image("solomon11/jenk:latest")
                        image.push()
                    }
                }
            }
        }
    }

    post {
        always {

            cleanWs()


        }
    }
}
