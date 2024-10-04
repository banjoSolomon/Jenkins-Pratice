pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        DOCKER_IMAGE_NAME = 'solomon11/jenkins'
        DOCKER_IMAGE_TAG = 'latest'
        AWS_CREDENTIALS_ID = 'aws-credentials'
        AWS_REGION = 'us-east-1'
        INSTANCE_TYPE = 't2.micro'
        AMI_ID = 'ami-0866a3c8686eaeeba' // Change this to your required AMI
        KEY_NAME = 'terraform' // Ensure this key is available in your local SSH
        POSTGRES_USER = 'postgres'
        POSTGRES_PASSWORD = 'password'
        POSTGRES_DB = 'Jenkins_db'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'in-dev', url: 'https://github.com/banjoSolomon/Jenkins-Pratice.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh "echo \$DOCKER_PASSWORD | docker login -u \$DOCKER_USERNAME --password-stdin"
                        sh "docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ."
                        sh "docker push ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
                    }
                }
            }
        }

        // Move the method definition outside of the stages
        script {
            def getInstanceState(String instanceId) {
                def maxRetries = 3
                def attempt = 0
                def instanceState = ""

                while (attempt < maxRetries) {
                    try {
                        instanceState = sh(script: "aws ec2 describe-instances --instance-ids ${instanceId} --query 'Reservations[0].Instances[0].State.Name' --output text", returnStdout: true).trim()
                        return instanceState
                    } catch (Exception e) {
                        echo "Attempt ${attempt + 1} failed: ${e.message}"
                        sleep(10) // Wait before retrying
                        attempt++
                    }
                }
                error "Failed to get instance state after ${maxRetries} attempts."
            }
        }

        stage('Create EC2 Instance with Default Security Group') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                        // Create EC2 instance and get its ID
                        def instanceId = sh(script: """
                            aws ec2 run-instances \
                                --image-id ${AMI_ID} \
                                --instance-type ${INSTANCE_TYPE} \
                                --key-name ${KEY_NAME} \
                                --region ${AWS_REGION} \
                                --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Jenkins}] \
                                --query 'Instances[0].InstanceId' \
                                --output text
                        """, returnStdout: true).trim()
                        echo "Instance ID: ${instanceId}"

                        // Poll for instance state using the method
                        def instanceState = getInstanceState(instanceId)

                        // Retrieve Public IP of the instance
                        def ec2PublicIp = sh(script: """
                            aws ec2 describe-instances \
                                --instance-id ${instanceId} \
                                --query 'Reservations[0].Instances[0].PublicIpAddress' \
                                --output text
                        """, returnStdout: true).trim()
                        echo "Public IP: ${ec2PublicIp}"

                        // Store values for later use
                        writeFile file: 'instance_id.txt', text: instanceId
                        writeFile file: 'ec2_public_ip.txt', text: ec2PublicIp
                    }
                }
            }
        }

        // Remaining stages...
    }

    post {
        always {
            cleanWs()
        }
    }
}
