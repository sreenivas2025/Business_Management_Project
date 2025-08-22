pipeline {
    agent any

    environment {
        REGISTRY = "docker.io"
        IMAGE_NAME = "vsiraparapu/business-mgmt-app"
        SONAR_HOST_URL = "http://sonarqube.local"
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


        // stage("Upload Artifacts") {
        //     steps {
        //         nexusArtifactUploader(
        //             nexusVersion: 'nexus3',
        //             protocol: 'http',
        //             nexusUrl: 'nexus:8081',
        //             groupId: 'com.business',
        //             version: '0.0.1-SNAPSHOT',
        //             repository: 'maven-snapshots',
        //             credentialsId: 'nexus-jenkins-creds',
        //             artifacts: [
        //                 [artifactId: 'business-mgmt-app',
        //                 classifier: '',
        //                 file: 'target/BusinessProject-0.0.1-SNAPSHOT.jar',
        //                 type: 'jar']
        //             ]
        //         )
        //     }
        // }




        // stage ("Build App Image") {
        //     steps {
        //         sh "docker build -t ${REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER} ."
        //     }
        // }

        // stage ("Push App Image") {
        //     steps {
        //         withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
        //             sh """
        //                echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
        //                docker push ${REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER}
        //             """
        //         }
        //     }
        // }

        // stage ("Deploy to cluster dev-kt-k8s") {
        //     steps {
        //         withKubeConfig(credentialsId: 'kubeconfig-dev-kt-k8s') {
        //             sh "kubectl apply -f k8s/business-mgmt-app-deploy.yaml"
        //         }
        //     }
        // }
    }
}

