pipeline {
    agent any

    environment {
        REGISTRY = "docker.io"
        IMAGE_NAME = "vsiraparapu/business-mgmt-app"
        SONAR_HOST_URL = "http://your-sonarqube-server:9000"
        SONAR_SCANNER = "sonar-scanner" // sonar scanner tool must be configured in Jenkins
    }

    stages {
        stage ("Checkout Code") {
            steps {
                git branch: 'main', url: 'https://github.com/your-org/business-mgmt-app.git'
            }
        }

        stage ("Build Code") {
            steps {
                sh "mvn clean install -DskipTests"
            }
        }

        stage ("Run Code Scanning") {
            steps {
                withSonarQubeEnv('SonarQube') { // Jenkins SonarQube server config name
                    sh '''
                        ${SONAR_SCANNER} \
                          -Dsonar.projectKey=business-mgmt-app \
                          -Dsonar.projectName=business-mgmt-app \
                          -Dsonar.sources=src \
                          -Dsonar.java.binaries=target/classes
                    '''
                }
            }
        }

        stage ("Check Quality Gate") {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage ("Run Tests") {
            steps {
                sh "mvn test"
            }
        }

        stage ("Upload Artifacts") {
            steps {
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        stage ("Build App Image") {
            steps {
                sh "docker build -t ${REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER} ."
            }
        }

        stage ("Push App Image") {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                       echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                       docker push ${REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER}
                    """
                }
            }
        }

        stage ("Deploy to cluster dev-kt-k8s") {
            steps {
                withKubeConfig(credentialsId: 'kubeconfig-dev-kt-k8s') {
                    sh "kubectl apply -f k8s/business-mgmt-app-deploy.yaml"
                }
            }
        }
    }
}
