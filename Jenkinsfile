pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        DOCKER_IMAGE_NAME = 'solomon11/jenkins'
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
                    setupEC2Instance(ec2PublicIp)
                    waitForPostgreSQL(ec2PublicIp)
                    runDockerContainer(ec2PublicIp)
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
            aws ec2 authorize-security-group-ingress --group-id ${securityGroupId} --protocol tcp --port 80 --cidr 0.0.0.0/0 --region ${AWS_REGION}
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

def setupEC2Instance(String ec2PublicIp) {
    sshagent (credentials: ['ec2-ssh-credentials']) {
        sh """
        ssh -o StrictHostKeyChecking=no ubuntu@${ec2PublicIp} <<EOF
        sudo apt-get update
        sudo apt-get install -y docker.io postgresql postgresql-contrib
        sudo systemctl start docker
        sudo systemctl enable docker

        sudo systemctl start postgresql
        sudo systemctl enable postgresql

        # Get the installed PostgreSQL version
        PG_VERSION=\$(psql --version | awk '{print \$3}' | cut -d '.' -f 1)

        # PostgreSQL setup
        sudo -i -u postgres psql -c "CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';"
        sudo -i -u postgres psql -c "CREATE DATABASE ${POSTGRES_DB};"
        sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};"

        # Allow remote connections
        echo "listen_addresses='*'" | sudo tee -a /etc/postgresql/\${PG_VERSION}/main/postgresql.conf
        echo "host all all 0.0.0.0/0 md5" | sudo tee -a /etc/postgresql/\${PG_VERSION}/main/pg_hba.conf
        sudo systemctl restart postgresql
        EOF
        """
    }
}

def waitForPostgreSQL(String ec2PublicIp) {
    sshagent (credentials: ['ec2-ssh-credentials']) {
        retry(5) {
            sleep 10
            def postgresStatus = sh(script: """
                ssh -o StrictHostKeyChecking=no ubuntu@${ec2PublicIp} "sudo systemctl is-active postgresql"
            """, returnStdout: true).trim()

            echo "PostgreSQL status: ${postgresStatus}"

            if (postgresStatus != "active") {
                error("PostgreSQL not active yet, waiting...")
            }
        }
    }
}

def runDockerContainer(String ec2PublicIp) {
    sshagent (credentials: ['ec2-ssh-credentials']) {
        sh """
        ssh -o StrictHostKeyChecking=no ubuntu@${ec2PublicIp} <<EOF
        docker run -d --name my-app-container \
            -e POSTGRES_USER=${POSTGRES_USER} \
            -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
            -e POSTGRES_DB=${POSTGRES_DB} \
            -p 80:80 \
            ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
        EOF
        """
    }
}
