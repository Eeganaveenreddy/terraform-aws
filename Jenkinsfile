pipeline{
    agent any
    
    environment { 
        APP_NAME = "ERP-Odoo" 
        ENVIRONMENT = "UAT" 
        // Team recipients 
        MAIL_TO = "enreddy619@gmail.com" 
        DEFAULT_MAIL= "enreddy619@gmail.com" 
    }

    options{
        disableConcurrentBuilds(abortPrevious: true)
        buildDiscarder(logRotator(
            numToKeepStr: '10',
            artifactNumToKeepStr: '3'
        ))
        timestamps()
        timeout(time: 10, unit: 'MINUTES')
    }
    stages{
        stage('Get Triggered User'){
            steps{
                script{
                    /*
                    STARTTIME -> Raw epoch timestamp in milliseconds (used for duration calculation)
                    START_TIME -> Human‑readable formatted time (used for logs/emails)
                    */
                    env.STARTTIME = System.currentTimeMillis().toString()
                    env.START_TIME = new Date().format(
                        'yyyy-MM-dd hh:mm a',
                        TimeZone.getTimeZone('Asia/Kolkata')
                    )

                            // Get triggering user (modern Jenkins way)
                            wrap([$class: 'BuildUser']) {
                                env.TRIGGERED_USER = env.BUILD_USER ?: 'SCM/Automation'
                                env.USER_EMAIL     = env.BUILD_USER_EMAIL ?: env.DEFAULT_MAIL
                            }

                            echo "Triggered User: ${env.TRIGGERED_USER}"
                            echo "Deployment initiated by: ${env.TRIGGERED_USER}"
                            echo "Deployment started at: ${env.START_TIME}"
                }
            }
        }

        stage('Send Inialization Mail'){
            steps{
                script {
                    def recipients = "${env.MAIL_TO}"
                    emailext(
                    to: recipients,
                    mimeType: 'text/html',
                    subject: "Code Deployment Initiated: ${env.APP_NAME} deployment to ${env.ENVIRONMENT}",
                    body: """
                    Application: ${env.APP_NAME} <br>
                    Environment: ${env.ENVIRONMENT} <br>
                    Start Time: ${env.START_TIME} <br>
                    Build Number: ${env.BUILD_NUMBER} <br>

                    Deployment initiated by <b>${env.TRIGGERED_USER}</b>. <br><br>
                        Please login to Jenkins and Enter details to deploy.
                        <br><br>
                        <a href="${env.BUILD_URL}input">Click here to go to the build</a>
                    """
                    )
                }
            }
        }
    }
}