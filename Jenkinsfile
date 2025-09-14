pipeline {
    agent any
     parameters {
        choice(name: 'DEPLOY_ENV', choices: ['dev', 'prod'], description: 'Choose which environment to deploy: dev or prod')
        choice(name: 'DOCKER_TAG', choices: ['dev', 'prod'], description: 'Choose the Docker image tag for the deployment')
        booleanParam(name: 'SWITCH_TRAFFIC', defaultValue: false, description: 'Switch traffic between dev and prod')
    }

    environment {
        REGISTRY = "docker.io"
        IMAGE_NAME = "psrao2025/business-mgmt-app"
        TAG = "${params.DOCKER_TAG}"
        
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
                    def scannerHome = tool name: 'sonar-scanner-7.2.0', type: 'hudson.plugins.sonar.SonarRunnerInstallation'

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
    }
}

//         stage("Upload Artifacts") {
//             steps {
//                 nexusArtifactUploader(
//                     nexusVersion: 'nexus3',
//                     protocol: 'http',
//                     nexusUrl: 'nexus:8081',
//                     groupId: 'com.business',
//                     version: '0.0.1-SNAPSHOT',   // must match POM
//                     repository: 'maven-snapshots',  // snapshot repo
//                     credentialsId: 'nexus-jenkins-creds',
//                     artifacts: [
//                         [artifactId: 'BusinessProject',    // must match POM
//                         classifier: '',
//                         file: 'target/BusinessProject-0.0.1-SNAPSHOT.jar',
//                         type: 'jar']
//                     ]
//                 )
//             }
//         }


//         stage ("Build App Image") {
//             steps {
//                 script {
                
//                     // Build Docker image
//                     sh "docker build -t ${REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER} ."
//                 }
//             }
//         }
        

//         stage ("Push App Image") {
//             steps {
              
//                 withCredentials([usernamePassword(credentialsId: 'docker-jenkins-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
//                     sh """
//                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
//                        docker push ${REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER}
//                     """
//                 }
//             }
//         }

//         stage ("Deploy to cluster dev-kt-k8s") {
//             steps {
//                 withKubeConfig(credentialsId: 'kubeconfig-dev-kt-k8s') {
//                     sh "kubectl apply -f k8s/namespace.yaml"
//                     sh "kubectl apply -f k8s/mysql/"

//                     sh """
//                         sed -i 's#docker.io/vsiraparapu/business-mgmt-app:[0-9]\\+#docker.io/vsiraparapu/business-mgmt-app:${BUILD_NUMBER}#' k8s/app/deployment.yaml
//                         kubectl apply -f k8s/app/
//                     """
//                 }
//             }
//         }
//     }
// }

