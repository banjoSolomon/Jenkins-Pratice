pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        DOCKER_IMAGE_NAME = 'solomon11/jenkins'
        DOCKER_IMAGE_TAG = 'latest'
        AWS_CREDENTIALS_ID = 'aws-credentials'
        AWS_REGION = 'us-east-1a'
        INSTANCE_TYPE = 't2.micro'
        AMI_ID = 'ami-0866a3c8686eaeeba'
        KEY_NAME = 'terraform'
        POSTGRES_USER = 'postgres'
        POSTGRES_PASSWORD = 'password'
        POSTGRES_DB = 'Jenkins_db'
        INSTANCE_NAME = 'Jenkins'
        SECURITY_GROUP_NAME = 'Jenkins_security'
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
                    dockerLogin()
                    buildAndPushDockerImage()
                }
            }
        }

        stage('Setup EC2 Instance') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                        def securityGroupId = setupSecurityGroup()
                        def instanceId = launchInstance(securityGroupId)
                        waitForInstance(instanceId)
                        def ec2PublicIp = getPublicIp(instanceId)
                        writeFile file: 'instance_id.txt', text: instanceId
                        writeFile file: 'ec2_public_ip.txt', text: ec2PublicIp
                    }
                }
            }
        }

        stage('Configure EC2 Instance') {
            steps {
                script {
                    sshagent (credentials: ['ec2-ssh-credentials']) {
                        configureInstance(readFile('ec2_public_ip.txt').trim())
                    }
                }
            }
        }

        stage('Run Docker Container') {
            steps {
                script {
                    sshagent (credentials: ['ec2-ssh-credentials']) {
                        runDockerContainer(readFile('ec2_public_ip.txt').trim())
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

// Function to log in to Docker
def dockerLogin() {
    withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
        sh "echo \$DOCKER_PASSWORD | docker login -u \$DOCKER_USERNAME --password-stdin"
    }
}

// Function to build and push Docker image
def buildAndPushDockerImage() {
    sh "docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ."
    sh "docker push ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
}

// Function to setup security group
def setupSecurityGroup() {
    def securityGroupId = sh(script: "aws ec2 describe-security-groups --group-names ${env.SECURITY_GROUP_NAME} --query 'SecurityGroups[0].GroupId' --output text || true", returnStdout: true).trim()

    if (!securityGroupId) {
        securityGroupId = sh(script: """
            aws ec2 create-security-group --group-name ${env.SECURITY_GROUP_NAME} --description 'Security group for EC2 instance' --query 'GroupId' --output text
        """, returnStdout: true).trim()
        echo "Created Security Group ID: ${securityGroupId}"

        // Add ingress rules
        sh """
            aws ec2 authorize-security-group-ingress --group-id ${securityGroupId} --protocol tcp --port 22 --cidr 0.0.0.0/0
            aws ec2 authorize-security-group-ingress --group-id ${securityGroupId} --protocol tcp --port 80 --cidr 0.0.0.0/0
        """
    } else {
        echo "Security Group already exists: ${securityGroupId}"
    }

    return securityGroupId
}

// Function to launch EC2 instance
def launchInstance(securityGroupId) {
    def instanceId = sh(script: """
        aws ec2 run-instances \
            --image-id ${env.AMI_ID} \
            --instance-type ${env.INSTANCE_TYPE} \
            --key-name ${env.KEY_NAME} \
            --security-group-ids ${securityGroupId} \
            --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=${env.INSTANCE_NAME}}]' \
            --query 'Instances[0].InstanceId' \
            --output text
    """, returnStdout: true).trim()

    echo "Created Instance ID: ${instanceId}"
    return instanceId
}

// Function to wait for EC2 instance to be running
def waitForInstance(instanceId) {
    retry(3) {
        sh "aws ec2 wait instance-running --instance-ids ${instanceId} --region ${env.AWS_REGION}"
    }
}

// Function to get public IP of EC2 instance
def getPublicIp(instanceId) {
    def ec2PublicIp = sh(script: """
        aws ec2 describe-instances \
            --instance-ids ${instanceId} \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text
    """, returnStdout: true).trim()

    echo "Public IP: ${ec2PublicIp}"
    return ec2PublicIp
}

// Function to configure EC2 instance
def configureInstance(ec2PublicIp) {
    sh """
    ssh -o StrictHostKeyChecking=no ec2-user@${ec2PublicIp} <<EOF
        sudo apt-get update
        sudo apt-get install -y docker.io postgresql postgresql-contrib
        sudo systemctl start docker
        sudo systemctl enable docker

        sudo systemctl start postgresql
        sudo systemctl enable postgresql

        # Configure PostgreSQL
        sudo -i -u postgres psql -c "CREATE USER ${env.POSTGRES_USER} WITH PASSWORD '${env.POSTGRES_PASSWORD}';"
        sudo -i -u postgres psql -c "CREATE DATABASE ${env.POSTGRES_DB};"
        sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${env.POSTGRES_DB} TO ${env.POSTGRES_USER};"

        echo "listen_addresses='*'" | sudo tee -a /etc/postgresql/13/main/postgresql.conf
        echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /etc/postgresql/13/main/pg_hba.conf
        sudo systemctl restart postgresql
    EOF
    """
}

// Function to run the Docker container
def runDockerContainer(ec2PublicIp) {
    sh """
    ssh -o StrictHostKeyChecking=no ec2-user@${ec2PublicIp} <<EOF
        docker run -d --name my-app-container \
            -e POSTGRES_USER=${env.POSTGRES_USER} \
            -e POSTGRES_PASSWORD=${env.POSTGRES_PASSWORD} \
            -e POSTGRES_DB=${env.POSTGRES_DB} \
            -p 80:80 \
            ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}
    EOF
    """
}
