pipeline {
    agent any

    environment {
        REGISTRY_URL = "wimetrixcregistery.azurecr.io"
        REGISTRY_CREDENTIALS_ID = "acr-credentials"
        //IMAGE_NAME = "wimetrixcregistery/utopia-Nishat-frontend-pack-station"
        GIT_CREDENTIALS_ID = "GithubCredentials"
        SOURCE_REPO = "github.com/WiMetrixDev/sooperwizer.git"
        WORKSPACE_DIR = "/home/jenkins/deployment-package/wimetrix/Nishat-frontend-pack-station"
        GITHUB_REPO = 'github.com/WiMetrixDev/dep-Nishat-frontend-pack-station.git'

    }

    stages {

            stage('Set Environment Variables') {
            steps {
                script
                {
                    
                    if (params.DEP_BRANCH == 'main') {
                        env.IMAGE_NAME = "wimetrixcregistery/Nishat-frontend-pack-station"
                    } 
                    
                    else if (params.DEP_BRANCH == 'qa') {
                        env.IMAGE_NAME = "wimetrixcregistery/Nishat-frontend-pack-stationqa"
                    } 
                    
                    else {
                        error "Branch not supported for deployment."
                    }
                    
                    echo "Using environment configuration for branch: ${env.DEP_BRANCH}"
                    echo "IMAGE_NAME: ${env.IMAGE_NAME}"
                    echo "WORKSPACE_DIR: ${env.WORKSPACE_DIR}"
                    echo "DEPLOYMENT_YAML: ${env.DEPLOYMENT_YAML}"
                }
            }
        }





        stage('Checkout') {
        steps {
            // Checkout first repo
            checkout([$class: 'GitSCM',
                    branches: [[name: 'remotes/origin/$DEP_BRANCH']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [
                        [$class: 'WipeWorkspace'],
                        [$class: 'RelativeTargetDirectory', relativeTargetDir: '/home/jenkins/deployment-package/wimetrix/Nishat-frontend-pack-station']
                    ],
                    submoduleCfg: [],
                    userRemoteConfigs: [[
                        credentialsId: 'GithubCredentials',
                        url: 'https://github.com/WiMetrixDev/dep-Nishat-frontend-pack-station.git'
                    ]]
            ])

            // Checkout second repo
            checkout([$class: 'GitSCM',
                    branches: [[name: 'remotes/origin/$SOURCE_BRANCH']], 
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [
                        [$class: 'WipeWorkspace'],
                        [$class: 'RelativeTargetDirectory', relativeTargetDir: '/home/jenkins/deployment-package/wimetrix/Nishat-frontend-pack-station/source']
                    ],
                    submoduleCfg: [],
                    userRemoteConfigs: [[
                        credentialsId: 'GithubCredentials',
                        url: 'https://github.com/WiMetrixDev/sooperwizer.git'
                    ]]
            ])
        }
    }


        stage('Build Docker Image') {
    steps {
        script {
            def dockerfileDir = '/home/jenkins/deployment-package/wimetrix/Nishat-frontend-pack-station/'
            def sourceDir = "${dockerfileDir}source"
            withCredentials([
                        file(credentialsId: 'NISHAT_FRONTEND_PRODUCTION', variable: 'SECRET_FILE')
                    ]){

                    sh label: '', script: '''
                        cp /home/jenkins/deployment-package/wimetrix/Nishat-frontend-pack-station/Dockerfile /home/jenkins/deployment-package/wimetrix/Nishat-frontend-pack-station/source/
                        cp /home/jenkins/deployment-package/wimetrix/Nishat-frontend-pack-station/.dockerignore /home/jenkins/deployment-package/wimetrix/Nishat-frontend-pack-station/source/
                        cd /home/jenkins/deployment-package/wimetrix/Nishat-frontend-pack-station/source/shared-env/web
                        cp ${SECRET_FILE} /home/jenkins/deployment-package/wimetrix/Nishat-frontend-pack-station/source/shared-env/web/.env.production
                '''
                dockerImage = docker.build("${REGISTRY_URL}/${IMAGE_NAME}:${env.BUILD_ID}",
                    "-f ${sourceDir}/Dockerfile ${sourceDir}")

                sh label: '', script: '''
                rm -rf /home/jenkins/deployment-package/wimetrix/Nishat-frontend-pack-station/source/*
                ''' 
                    }                 
            }
        }
    }
  

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry("https://${REGISTRY_URL}", "${REGISTRY_CREDENTIALS_ID}") {
                        dockerImage.push("${env.BUILD_ID}")
                        dockerImage.push("latest")

                    }
                }
            }
        }

        stage('Trigger GitHub Actions'){
            steps {
                script {
                    withCredentials([string(credentialsId: 'GITHUB_ACTIONS_SECRET', variable: 'GITHUB_ACTIONS')]){
                        def githubPAT = env.GITHUB_ACTIONS
                        def githubOwner = "WiMetrixDev"  
                        def githubRepo = "dep-Nishat-frontend-pack-station"  
                        def githubWorkflow = "production-deploy.yaml"  
                        def branch = "main" 

                        def apiUrl = "https://api.github.com/repos/${githubOwner}/${githubRepo}/actions/workflows/${githubWorkflow}/dispatches"

                        def payload = """
                        {
                            "ref": "${branch}"
                        }
                        """

                        echo "Triggering GitHub Actions workflow: ${githubWorkflow} for repo: ${githubRepo} on branch: ${branch}"
                        echo "API URL: ${apiUrl}"

                        def response = httpRequest(
                            url: apiUrl,
                            httpMode: 'POST',
                            contentType: 'APPLICATION_JSON',
                            customHeaders: [[name: 'Authorization', value: "Bearer ${githubPAT}"]],
                            requestBody: payload,
                            validResponseCodes: '201,204'
                        )

                        echo "GitHub API response: ${response}"
                    }
                    
                }
            }
        }


    }

    post {
        always {
            cleanWs()
        }
        success {
            script {
                // Use withCredentials to access the webhook URL from Jenkins credentials
                withCredentials([string(credentialsId: 'TEAMS_WEBHOOK_URL', variable: 'WEBHOOK_URL'),
                string(credentialsId: 'JENKINS_API_TOKEN', variable: 'JENKINS_TOKEN'),
                string(credentialsId: 'JENKINS_USER', variable: 'JENKINS_USER')
                ]
                ) {
                    def buildUrl = env.BUILD_URL // Get the Jenkins build URL
                    def logUrl = "${buildUrl}console" // Create a link to the build logs
                    def logs = "${buildUrl}consoleText"
                    def logContent = sh(script: "curl -u ${JENKINS_USER}:${JENKINS_TOKEN} -s ${buildUrl}consoleText", returnStdout: true).trim()

                    // Send notification to Teams with a link to the log file
                    office365ConnectorSend message: "Build Succeeded For $DEP_BRANCH. Check the logs \n```${logContent}``` ", 
                                           status: "Success", 
                                           webhookUrl: env.WEBHOOK_URL
                }
            }
         
        }
        failure {
            script {
                // Use withCredentials to access the webhook URL from Jenkins credentials    
                withCredentials([string(credentialsId: 'TEAMS_WEBHOOK_URL', variable: 'WEBHOOK_URL'),
                string(credentialsId: 'JENKINS_API_TOKEN', variable: 'JENKINS_TOKEN'),
                string(credentialsId: 'JENKINS_USER', variable: 'JENKINS_USER')
                ]
                ) {
                    def buildUrl = env.BUILD_URL
                    def logUrl = "${buildUrl}console"
                    def logs = "${buildUrl}consoleText"
                    def logContent = sh(script: "curl -u ${JENKINS_USER}:${JENKINS_TOKEN} -s ${buildUrl}consoleText", returnStdout: true).trim()

                    // Send notification to Teams with a link to the log file
                    office365ConnectorSend message: "Build Failed For $DEP_BRANCH. Check the logs \n```${logContent}```", 
                                           status: "Failed", 
                                           webhookUrl: env.WEBHOOK_URL
                }
            }
        }
    }
}
