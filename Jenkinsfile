def AWS_CREDENTIALS_ID = 'your-aws-credentials-id'
def AMI_ID = 'your-ami-id'
def INSTANCE_TYPE = 'your-instance-type'
def KEY_NAME = 'your-key-name'
def AWS_REGION = 'your-aws-region'
def POSTGRES_USER = 'your-postgres-user'
def POSTGRES_PASSWORD = 'your-postgres-password'
def POSTGRES_DB = 'your-postgres-db'
def DOCKER_IMAGE_NAME = 'your-docker-image-name'
def DOCKER_IMAGE_TAG = 'your-docker-image-tag'

pipeline {
    agent any

    stages {
        stage('Create EC2 Instance') {
            steps {
                script {
                    def instanceId = createEC2Instance()
                    def ec2PublicIp = getInstancePublicIp(instanceId)
                    setupEC2Instance(ec2PublicIp)
                    waitForPostgreSQL(ec2PublicIp)
                    runDockerContainer(ec2PublicIp)
                }
            }
        }
    }
}

def createEC2Instance() {
    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
        def instanceId = sh(script: """
            aws ec2 run-instances --image-id ${AMI_ID} --count 1 --instance-type ${INSTANCE_TYPE} --key-name ${KEY_NAME} --query 'Instances[0].InstanceId' \
                --output text --region ${AWS_REGION}
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
        ssh -o StrictHostKeyChecking=no ubuntu@${ec2PublicIp} << 'EOF'
        set -x  # Enable verbose logging
        # Update package list and install required packages
        sudo apt-get update
        sudo apt-get install -y docker.io postgresql postgresql-contrib

        # Start and enable Docker
        sudo systemctl start docker
        sudo systemctl enable docker

        # Start and enable PostgreSQL
        sudo systemctl start postgresql
        sudo systemctl enable postgresql

        # Check PostgreSQL status
        sudo systemctl status postgresql

        # Create PostgreSQL user if it does not exist
        sudo -i -u postgres psql -c "SELECT 1 FROM pg_roles WHERE rolname = '${POSTGRES_USER}'" | grep -q 1 || sudo -i -u postgres psql -c "CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';"

        # Create database if it does not exist
        sudo -i -u postgres psql -c "SELECT 1 FROM pg_database WHERE datname = '${POSTGRES_DB}'" | grep -q 1 || sudo -i -u postgres psql -c "CREATE DATABASE ${POSTGRES_DB};"

        # Grant privileges
        sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};"

        # Configure PostgreSQL for remote access
        PG_VERSION=\$(psql -V | awk '{print \$3}' | cut -d '.' -f 1)

        # Create directory if it doesn't exist
        sudo mkdir -p /etc/postgresql/\${PG_VERSION}/main/

        # Write configuration
        echo "listen_addresses='*'" | sudo tee /etc/postgresql/\${PG_VERSION}/main/postgresql.conf
        echo "host all all 0.0.0.0/0 md5" | sudo tee -a /etc/postgresql/\${PG_VERSION}/main/pg_hba.conf

        # Restart PostgreSQL to apply changes
        sudo systemctl restart postgresql

        # Verify PostgreSQL is running
        sudo systemctl status postgresql
        EOF
        """
    }
}

def waitForPostgreSQL(String ec2PublicIp) {
    retry(5) {
        sleep 20
        sh "ssh -o StrictHostKeyChecking=no ubuntu@${ec2PublicIp} 'pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}'"
    }
}

def runDockerContainer(String ec2PublicIp) {
    sshagent (credentials: ['ec2-ssh-credentials']) {
        sh """
        ssh -o StrictHostKeyChecking=no ubuntu@${ec2PublicIp} <<EOF
        sudo docker run -d -p 8080:8080 --name my-jenkins ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
        EOF
        """
    }
}