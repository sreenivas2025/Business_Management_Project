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
                    echo "📦 Loading Docker image into KIND cluster '${KIND_CLUSTER}'..."

                    // Verify Kind is installed
                    sh """
                        if ! command -v kind &> /dev/null; then
                        echo "Kind CLI not found. Installing temporarily..."
                        curl -Lo kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
                        chmod +x kind
                        sudo mv kind /usr/local/bin/
                        fi
                    """

                    // Verify cluster exists
                    sh """
                        if ! kind get clusters | grep -q "^${KIND_CLUSTER}\$"; then
                        echo "Cluster '${KIND_CLUSTER}' not found. Please create it using 'kind create cluster --name ${KIND_CLUSTER}'"
                        exit 1
                        fi
                    """

                    // Load Docker image into Kind
                    sh """
                        echo "Loading image ${IMAGE_NAME}:${env.BUILD_NUMBER} into cluster ${KIND_CLUSTER}..."
                        kind load docker-image ${IMAGE_NAME}:${env.BUILD_NUMBER} --name ${KIND_CLUSTER}
                    """

                    echo "✅ Image loaded successfully into Kind cluster!"
                }
            }
        }
    }
}
//         stage("Deploy to KIND Cluster") {
//             steps {
//                 withKubeConfig(credentialsId: 'kubeconfig-kind') {
//                     sh """
//                         echo "Deploying to KIND cluster..."
//                         kubectl apply -f k8s/namespace.yaml
//                         kubectl apply -f k8s/mysql/
//                         sed -i "s#business-mgmt-app:[0-9]\\+#business-mgmt-app:${BUILD_NUMBER}#g" k8s/app/deployment.yaml
//                         kubectl apply -f k8s/app/
//                     """
//                 }
//             }
//         }
//     stage("Verify Deployment") {
//             steps {
//                 sh """
//                     kubectl get pods -n businessproject 
//                     kubectl get svc -n businessproject 
//                 """
//             }
//         }
//     }
// }




