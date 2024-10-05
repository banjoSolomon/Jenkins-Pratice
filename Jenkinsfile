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

        stage('Create EC2 Instance and Security Group') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                        // Create security group with SSH and HTTP access
                        def securityGroupId = sh(script: """
                            aws ec2 create-security-group --group-name my-security-group --description 'Security group for EC2 instance' --query 'GroupId' --output text
                        """, returnStdout: true).trim()

                        echo "Security Group ID: ${securityGroupId}"

                        // Add rules to allow SSH (22) and HTTP (80)
                        sh """
                            aws ec2 authorize-security-group-ingress --group-id ${securityGroupId} --protocol tcp --port 22 --cidr 0.0.0.0/0
                            aws ec2 authorize-security-group-ingress --group-id ${securityGroupId} --protocol tcp --port 80 --cidr 0.0.0.0/0
                        """

                        // Launch EC2 instance with security group
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

                        // Check if the instance is in the 'pending' or 'running' state
                        retry(5) {
                            sleep 20
                            def instanceState = sh(script: """
                                aws ec2 describe-instances \
                                    --instance-ids ${instanceId} \
                                    --query 'Reservations[0].Instances[0].State.Name' \
                                    --output text
                            """, returnStdout: true).trim()

                            echo "Instance state: ${instanceState}"

                            if (instanceState != "pending" && instanceState != "running") {
                                error("Waiting for instance to be registered")
                            }
                        }

                        // Wait until the instance is running
                        retry(3) {
                            sh "aws ec2 wait instance-running --instance-ids ${instanceId}"
                        }

                        // Get the public IP
                        def ec2PublicIp = sh(script: """
                            aws ec2 describe-instances \
                                --instance-ids ${instanceId} \
                                --query 'Reservations[0].Instances[0].PublicIpAddress' \
                                --output text
                        """, returnStdout: true).trim()

                        echo "Public IP: ${ec2PublicIp}"

                        // Save instance details
                        writeFile file: 'instance_id.txt', text: instanceId
                        writeFile file: 'ec2_public_ip.txt', text: ec2PublicIp
                    }
                }
            }
        }

        stage('Install Docker and PostgreSQL on EC2') {
            steps {
                script {
                    sshagent (credentials: ['ec2-ssh-credentials']) {
                        def ec2PublicIp = readFile('ec2_public_ip.txt').trim()
                        sh """
                        ssh -o StrictHostKeyChecking=no ec2-user@${ec2PublicIp} <<EOF
                        sudo apt-get update
                        sudo apt-get install -y docker.io postgresql postgresql-contrib
                        sudo systemctl start docker
                        sudo systemctl enable docker

                        sudo systemctl start postgresql
                        sudo systemctl enable postgresql

                        # Configure PostgreSQL
                        sudo -i -u postgres psql -c "CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';"
                        sudo -i -u postgres psql -c "CREATE DATABASE ${POSTGRES_DB};"
                        sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};"

                        echo "listen_addresses='*'" | sudo tee -a /etc/postgresql/13/main/postgresql.conf
                        echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /etc/postgresql/13/main/pg_hba.conf
                        sudo systemctl restart postgresql
                        EOF
                        """
                    }
                }
            }
        }

        stage('Run Docker Container') {
            steps {
                script {
                    sshagent (credentials: ['ec2-ssh-credentials']) {
                        def ec2PublicIp = readFile('ec2_public_ip.txt').trim()
                        sh """
                        ssh -o StrictHostKeyChecking=no ec2-user@${ec2PublicIp} <<EOF
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
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
