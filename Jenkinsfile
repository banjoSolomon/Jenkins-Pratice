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

        stage('Create EC2 Instance') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                        // Launch EC2 instance without specifying a security group (using default security group)
                        def instanceId = sh(script: """
                            aws ec2 run-instances \
                                --image-id ${AMI_ID} \
                                --instance-type ${INSTANCE_TYPE} \
                                --key-name ${KEY_NAME} \
                                --region ${AWS_REGION} \
                                --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_NAME}}]' \
                                --query 'Instances[0].InstanceId' \
                                --output text
                        """, returnStdout: true).trim()

                        echo "Instance ID: ${instanceId}"

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
                        sudo yum update -y
                        sudo amazon-linux-extras install docker
                        sudo service docker start
                        sudo usermod -a -G docker ec2-user

                        sudo yum install -y postgresql postgresql-server postgresql-devel
                        sudo postgresql-setup initdb
                        sudo systemctl start postgresql
                        sudo systemctl enable postgresql

                        # Configure PostgreSQL
                        sudo -i -u postgres psql -c "CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';"
                        sudo -i -u postgres psql -c "CREATE DATABASE ${POSTGRES_DB};"
                        sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};"

                        echo "listen_addresses='*'" | sudo tee -a /var/lib/pgsql/data/postgresql.conf
                        echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /var/lib/pgsql/data/pg_hba.conf
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
