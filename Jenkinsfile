pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        DOCKER_IMAGE_NAME = 'solomon11/content'
        DOCKER_IMAGE_TAG = 'latest'
        AWS_CREDENTIALS_ID = 'aws-credentials'
        AWS_REGION = 'us-east-1'
        INSTANCE_TYPE = 't2.micro'
        AMI_ID = 'ami-0866a3c8686eaeeba'
        KEY_NAME = 'terraform'
        POSTGRES_USER = 'postgres'
        POSTGRES_PASSWORD = 'password'
        POSTGRES_DB = 'Jenkins_db'
        INSTANCE_NAME = 'Jenkins'
        DOCKER_NETWORK = 'jenkins_network'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'in-dev', url: 'https://github.com/banjoSolomon/Jenkins-Pratice.git'
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    buildAndPushDockerImage()
                }
            }
        }

        stage('Setup EC2 Environment') {
            steps {
                script {
                    def securityGroupId = createSecurityGroup()
                    def instanceId = launchEC2Instance(securityGroupId)
                    def ec2PublicIp = getInstancePublicIp(instanceId)
                    setupDockerEnvironment(ec2PublicIp)
                }
            }
        }
    }

    post {
        always {
            cleanWs() // Clean workspace after execution
        }
    }
}

// Helper functions

def buildAndPushDockerImage() {
    withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
        sh "echo \$DOCKER_PASSWORD | docker login -u \$DOCKER_USERNAME --password-stdin"
        sh "docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ."
        sh "docker push ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
    }
}

def createSecurityGroup() {
    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
        def securityGroupName = "my-security-group-${System.currentTimeMillis()}"
        def securityGroupId = sh(script: """
            aws ec2 create-security-group --group-name ${securityGroupName} --description 'Security group for EC2 instance' --query 'GroupId' --output text --region ${AWS_REGION}
        """, returnStdout: true).trim()

        echo "Security Group ID: ${securityGroupId}"

        // Allow SSH and HTTP access
        sh """
            aws ec2 authorize-security-group-ingress --group-id ${securityGroupId} --protocol tcp --port 22 --cidr 0.0.0.0/0 --region ${AWS_REGION}
            aws ec2 authorize-security-group-ingress --group-id ${securityGroupId} --protocol tcp --port 8080 --cidr 0.0.0.0/0 --region ${AWS_REGION}  # Allow Jenkins access
            aws ec2 authorize-security-group-ingress --group-id ${securityGroupId} --protocol tcp --port 5432 --cidr 0.0.0.0/0 --region ${AWS_REGION}  # Allow PostgreSQL access
        """

        return securityGroupId
    }
}

def launchEC2Instance(String securityGroupId) {
    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
        def instanceId = sh(script: """
            aws ec2 run-instances \
                --image-id ${AMI_ID} \
                --instance-type ${INSTANCE_TYPE} \
                --key-name ${KEY_NAME} \
                --region ${AWS_REGION} \
                --security-group-ids ${securityGroupId} \
                --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_NAME}}]' \
                --query 'Instances[0].InstanceId' \
                --output text
        """, returnStdout: true).trim()

        echo "Instance ID: ${instanceId}"
        waitForInstanceToBeRunning(instanceId)
        return instanceId
    }
}

def waitForInstanceToBeRunning(String instanceId) {
    retry(5) {
        sleep 20
        def instanceState = sh(script: """
            aws ec2 describe-instances --instance-ids ${instanceId} --query 'Reservations[0].Instances[0].State.Name' --output text --region ${AWS_REGION}
        """, returnStdout: true).trim()

        echo "Instance state: ${instanceState}"

        if (instanceState != "running") {
            error("Instance not ready yet, waiting...")
        }
    }
}

def getInstancePublicIp(String instanceId) {
    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
        def ec2PublicIp = sh(script: """
            aws ec2 describe-instances --instance-ids ${instanceId} --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region ${AWS_REGION}
        """, returnStdout: true).trim()

        echo "Public IP: ${ec2PublicIp}"
        writeFile file: 'ec2_public_ip.txt', text: ec2PublicIp
        return ec2PublicIp
    }
}

def setupDockerEnvironment(String ec2PublicIp) {
    sshagent (credentials: ['ec2-ssh-credentials']) {
        // Install Docker if not already installed
        sh "ssh -o StrictHostKeyChecking=no ubuntu@${ec2PublicIp} 'sudo apt-get update && sudo apt-get install -y docker.io'"

        // Create Docker network
        sh "ssh -o StrictHostKeyChecking=no ubuntu@${ec2PublicIp} 'sudo docker network create ${DOCKER_NETWORK}'"

        // Run PostgreSQL container
        sh """
            ssh -o StrictHostKeyChecking=no ubuntu@${ec2PublicIp} 'sudo docker run -d \
                --name postgres-container \
                --network ${DOCKER_NETWORK} \
                -e POSTGRES_USER=${POSTGRES_USER} \
                -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
                -e POSTGRES_DB=${POSTGRES_DB} \
                -p 5432:5432 \
                postgres'
        """


        sh """
            ssh -o StrictHostKeyChecking=no ubuntu@${ec2PublicIp} 'sudo docker run -d \
                --name jenkins-container \
                --network ${DOCKER_NETWORK} \
                -e SPRING_DATASOURCE_URL=jdbc:postgresql://postgres-container:5432/${POSTGRES_DB} \
                -e SPRING_DATASOURCE_USERNAME=${POSTGRES_USER} \
                -e SPRING_DATASOURCE_PASSWORD=${POSTGRES_PASSWORD} \
                -p 8080:8080 \
                ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
                -Djenkins.install.runSetupWizard=false'
        """
    }
}
