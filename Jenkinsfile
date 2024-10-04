pipeline {
    agent any

    stages {
        stage('Create EC2 Instance') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentials',
                credentialsId: 'your-aws-credentials-id']]) {
                    script {
                        // Run the instance
                        def instanceId = sh(script: "aws ec2 run-instances --image-id ami-0866a3c8686eaeeba --instance-type t2.micro --key-name terraform --region us-east-1 --tag-specifications ResourceType=instance,Tags=[{Key=Name,Value=Jenkins}] --query Instances[0].InstanceId --output text", returnStdout: true).trim()
                        echo "Instance ID: ${instanceId}"

                        // Sleep longer for instance creation
                        sleep(time: 60, unit: 'SECONDS')

                        // Retry mechanism for describing the instance
                        def maxRetries = 5
                        def retries = 0
                        def state

                        while (retries < maxRetries) {
                            state = sh(script: "aws ec2 describe-instances --instance-ids ${instanceId} --query Reservations[0].Instances[0].State.Name --output text", returnStdout: true).trim()
                            if (state) {
                                break
                            }
                            echo "Waiting for instance to be ready..."
                            sleep(time: 15, unit: 'SECONDS')
                            retries++
                        }

                        if (state) {
                            echo "Instance state: ${state}"
                        } else {
                            error "Failed to retrieve instance state after retries"
                        }
                    }
                }
            }
        }

        stage('Install Docker and PostgreSQL on EC2') {
            steps {
                script {
                    // Commands to install Docker and PostgreSQL on the EC2 instance
                    // Make sure to replace 'user' and 'instanceIp' with actual user and IP of the instance
                    def instanceIp = sh(script: "aws ec2 describe-instances --instance-ids ${instanceId} --query Reservations[0].Instances[0].PublicIpAddress --output text", returnStdout: true).trim()

                    sh """
                    ssh -o StrictHostKeyChecking=no user@${instanceIp} << 'EOF'
                    sudo apt-get update
                    sudo apt-get install -y docker.io
                    sudo apt-get install -y postgresql postgresql-contrib
                    sudo systemctl start docker
                    sudo systemctl enable docker
                    EOF
                    """
                }
            }
        }

        stage('Run Docker Container') {
            steps {
                script {
                    // Replace 'your-docker-image' with the actual Docker image you want to run
                    def instanceIp = sh(script: "aws ec2 describe-instances --instance-ids ${instanceId} --query Reservations[0].Instances[0].PublicIpAddress --output text", returnStdout: true).trim()

                    sh """
                    ssh -o StrictHostKeyChecking=no user@${instanceIp} << 'EOF'
                    sudo docker run -d --name your-container-name your-docker-image
                    EOF
                    """
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
