pipeline {
    agent any
    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['dev', 'prod'], description: 'Choose environment to deploy: dev or prod')
        string(name: 'DOCKER_TAG', defaultValue: 'latest', description: 'Docker image tag (example: latest or build number)')
    }
     environment {
        IMAGE_NAME = "business-mgmt-app"
        KIND_CLUSTER = "kbgmt"
    }
    stages {

        stage("Build Code") {
            tools {
                maven 'maven-3.9.11'
            }
            steps {
                sh "mvn clean install -DskipTests"
            }
        }

        stage("Run Code Scanning") {
            steps {
                script {
                    // resolve the Sonar Scanner installation path
                    def scannerHome = tool name: 'sonar-scanner-7.3.0', type: 'hudson.plugins.sonar.SonarRunnerInstallation'

                    withSonarQubeEnv('sonar-local') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=business-mgmt-app \
                            -Dsonar.projectName=business-mgmt-app \
                            -Dsonar.sources=src \
                            -Dsonar.java.binaries=target/classes
                        """
                    }
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
    
        stage("Upload Artifacts") {
            steps {
                nexusArtifactUploader(
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    nexusUrl: 'nexus:8081',
                    groupId: 'com.business',
                    version: '0.0.1-SNAPSHOT',   // must match POM
                    repository: 'maven-snapshots',  // snapshot repo
                    credentialsId: 'nexus-jenkins-creds',
                    artifacts: [
                        [artifactId: 'BusinessProject',    // must match POM
                        classifier: '',
                        file: 'target/BusinessProject-0.0.1-SNAPSHOT.jar',
                        type: 'jar']
                    ]
                )
            }
        }
       
        stage("Build Docker Image") {
            steps {
                script {
                    sh """
                        echo "Building Docker image..."
                        docker build -t ${IMAGE_NAME}:${env.BUILD_NUMBER} .
                    """
                }
            }
        }
        stage("Load Image into KIND Cluster") {
            steps {
                script {
                    echo "Loading image into KIND cluster named '${KIND_CLUSTER}'..."
                    sh """
                        kind load docker-image ${IMAGE_NAME}:${env.BUILD_NUMBER} --name ${KIND_CLUSTER}
                    """
                }
            }
        }
        stage("Deploy to KIND Cluster") {
            steps {
                withKubeConfig(credentialsId: 'kubeconfig-kind') {
                    sh """
                        echo "Deploying to KIND cluster..."
                        kubectl apply -f k8s/namespace.yaml
                        kubectl apply -f k8s/mysql/
                        sed -i 's#psrao2025/business-mgmt-app:[0-9]\\+#psrao2025/business-mgmt-app:${BUILD_NUMBER}#' k8s/app/deployment.yaml
                        kubectl apply -f k8s/app/
                    """
                }
            }
        }
    stage("Verify Deployment") {
            steps {
                sh """
                    kubectl get pods -n business-mgmt //namespace name
                    kubectl get svc -n business-mgmt //namespacename
                """
            }
        }
    }
}



