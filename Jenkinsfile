pipeline {
    agent any

    tools {
        maven 'maven'
    }

    environment {
        DOCKER_IMAGE = 'deviprasad7781/gitops'
        GITOPS_REPO  = 'https://github.com/Degu22/java-application-gitops.git'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out application source code from GitHub...'
                git branch: 'main',
                    url: 'https://github.com/Degu22/java-application.git'
            }
        }

        stage('SonarQube Scan') {
            steps {
                echo 'Executing SonarQube static code quality analysis...'
                sh 'ls -ltr'
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        mvn sonar:sonar \
                        -Dsonar.host.url=http://54.92.175.4:9000 \
                        -Dsonar.token=${SONAR_TOKEN}
                    '''
                }
            }
        }

        stage('Build Artifact') {
            steps {
                echo 'Compiling Java source code and packaging WAR artifact...'
                sh 'mvn clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker container image: ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                sh '''
                    docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} -f Dockerfile .
                '''
            }
        }

        stage('Scan Docker Image using Trivy') {
            steps {
                echo "Scanning container image ${DOCKER_IMAGE}:${BUILD_NUMBER} for security vulnerabilities..."
                sh '''
                    trivy image ${DOCKER_IMAGE}:${BUILD_NUMBER} || true
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "Publishing container image to Docker Hub registry..."
                    withCredentials([string(credentialsId: 'dockerhub-pass', variable: 'DOCKERHUB_PASS')]) {
                        sh '''
                            echo "$DOCKERHUB_PASS" | docker login \
                              -u deviprasad7781 \
                              --password-stdin
                        '''
                        sh '''
                            docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                        '''
                    }
                    echo 'Successfully pushed image to Docker Hub'
                }
            }
        }

        stage('Update Deployment File') {
            steps {
                echo 'Updating Kubernetes deployment image tag in separate GitOps repository...'
                dir('gitops') {
                    git branch: 'main',
                        url: "${GITOPS_REPO}"

                    withCredentials([string(credentialsId: 'github', variable: 'GITHUB_TOKEN')]) {
                        sh '''
                            git config user.email "degu22@student.bth.se"
                            git config user.name "Degu22"

                            sed -i "s|image: deviprasad7781/gitops:.*|image: ${DOCKER_IMAGE}:${BUILD_NUMBER}|" deploymentfiles/deployment.yml

                            git add deploymentfiles/deployment.yml
                            git commit -m "Update deployment image to version ${BUILD_NUMBER}" || true

                            git push https://${GITHUB_TOKEN}@github.com/Degu22/java-application-gitops.git HEAD:main
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace...'
            cleanWs deleteDirs: true, notFailBuild: true
        }
        success {
            echo "Pipeline succeeded for Build #${BUILD_NUMBER}."
        }
        failure {
            echo "Pipeline failed for Build #${BUILD_NUMBER}."
        }
    }
}
