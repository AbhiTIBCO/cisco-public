#!/bin/bash
### #!/usr/bin/env bash

###
# .SYNOPSIS
#   Script name: tci-deploy-flogo.sh
#   Version: 1.6.0
#   Date: 06/21/2023
#
# .DESCRIPTION
#  -- Action - deployApp: This script action deploys a flogo application to the target TCI Organization. It performs the following steps:
#   
#    - Performs a Logout to ensure there are no old sessions.
#    - Performs a new Login with the supplied credentials.
#    - Prints the App Details before deployment.
#    - Deploys the App alongwith overriding the app properties from the properties file.
#      + If App already exists, then 
#        * it deploys the new app as <AppName>_promote
#        * replaces the <AppName> with <AppName>_promote
#        * Deletes the <AppName>_promote.
#      + If App does not exist, then
#        * it deploys the new app as <AppName>
#    - Gets the status of the app to ensure all pending commands have completed successfully.
#    - Update the following app attributes:
#      + Update the instance count to match the target instance count.
#      + Update the deployment stage to 'Live'. This is the default behavior and cannot be controlled through input parameters.
#      + Update the endpoint visibility to public or private based on the input parameter value. Default is public.
#    - Check if all the attributes are updated. If any of the attributes is not updated, it attempts to update the attributes again.
#    - Prints the App Details post deployment.
#    - Peforms a log out to close the session..
#
#  -- Action - promoteApp: This script action copies a flogo application fromn the source TCI Organization to the target TCI Organization. It performs the following steps:
#   
#    - Performs a Logout to ensure there are no old sessions.
#    - Performs a new Login with the supplied credentials to the target TCI Organization.
#    - Deletes the promote app from the target TCI Organization, if the app exists.
#    - Prints the detail of the target app from the target TCI Organization, if the app exists.
#    - Performs a log out to close the session.
#    - Performs a new Login with the supplied credentials to the source TCI Organization.
#    - Copies the app from source TCI Organization to <appname>_promote in the target TCI Organization.
#    - Updates app variables in the <appname>_promote app.
#    - replaces the <AppName> with <AppName>_promote
#    - Deletes the <AppName>_promote from the target TCI Organization.
#    - Gets the status of the app to ensure all pending commands have completed successfully.
#    - Update the following app attributes:
#      + Update the instance count to match the target instance count.
#      + Update the deployment stage to 'Live'. This is the default behavior and cannot be controlled through input parameters.
#      + Update the endpoint visibility to public or private based on the input parameter value. Default is public.
#    - Check if all the attributes are updated. If any of the attributes is not updated, it attempts to update the attributes again.
#    - Prints the App Details post deployment.
#    - Peforms a log out to close the session.
#
#  -- Action - updateAppAttributes: This script action updates the attributes of a flogo application in the target TCI Organization. It performs the following steps:
#
#    - Performs a Logout to ensure there are no old sessions.
#    - Performs a new Login with the supplied credentials.
#    - Prints the App Details before deployment.
#    - Update the following app attributes:
#      + Update the instance count to match the target instance count.
#      + Update the deployment stage to 'Live'. This is the default behavior and cannot be controlled through input parameters.
#      + Update the endpoint visibility to public or private based on the input parameter value. Default is public.
#    - Check if all the attributes are updated. If any of the attributes is not updated, it attempts to update the attributes again.
#    - Prints the App Details post deployment.
#    - Peforms a log out to close the session.
#
#  -- Action - updateAppVariables: This script action updates the variables of a flogo application in the target TCI Organization. It performs the following steps:
#
#    - Performs a Logout to ensure there are no old sessions.
#    - Performs a new Login with the supplied credentials.
#    - Prints the App Details before deployment.
#    - Update the App Variables using the properties file for the target environment.
#    - Prints the App Details post deployment.
#    - Peforms a log out to close the session.
###

###
# User configurable global variables
###
#propertyFileRootDir=/apps/tibco/properties/
propertyFileRootDir=/Users/abbhatia/Desktop/automation/properties/
#flogoAppArtifactRootDir=/apps/tibco/apps/flogo/
flogoAppArtifactRootDir=/Users/abbhatia/Desktop/automation/apps/
#tibcliExe=/apps/tibco/tci-autodeploy/tibcli
tibcliExe=/Users/abbhatia/Desktop/automation/tci-deployment/tibcli

###
# Do not modify
###

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   	echo "This script allows to deploy a flogo app or update attributes of a flogo app"
   	echo ""
	echo ".NOTES"
	echo "    Setup & Usage"
	echo "    -------------"
	echo "    - Place this script in any directory of your choosing."
	echo "    - Update the following variable values."
	echo "      + propertyFileRootDir - Set this value to the full path of the directory where property files are stored."
	echo "      + flogoAppArtifactRootDir - Set this value to the full path of the directory where Flogo application artifacts are stored. The script automatically appends the sub-directory based on the app name."
	echo "      + tibcliExe - Set this value to the full path of the tibcli executable."
	echo "    - Execute:"
	echo "      + Open a terminal."
	echo "      + Navigate to the directory where script file is located."
	echo "        ** cd /Users/abhatia/Desktop/automation/tci-deployment"
	echo "      + Execute the script as shown below:"
	echo "        ** See the example below."
	echo ""      
	echo ".PARAMETER -h"
	echo "    Print this help"
	echo ".PARAMETER -sourceEnvironment"
	echo "    TCI Org name from where the app is to be copied. Only applicable to promoteApp action."
	echo ".PARAMETER -targetEnvironment"
	echo "    TCI Org name where the app is to be deployed."
	echo ".PARAMETER -region"
	echo "    TCI Org region."
	echo ".PARAMETER -username"
	echo "    Username with which the app is to be deployed."
	echo ".PARAMETER -password"
	echo "    Password for the username used."
	echo ".PARAMETER -appName"
	echo "    Name of the app."
	echo ".PARAMETER -targetAppInstanceCount"
	echo "    Target Instance count of the application."
	echo ".PARAMETER -targetAppEndpointVisibility"
	echo "    Target application endpoint visibility. Acceptable values are \"private\" or \"public\". Default value is \"public\"."
	echo ".PARAMETER -appAction"
	echo "    Supported actions for app are deployApp, promoteApp,updateAppVariables and updateAppAttributes"
	echo ""
	echo ".EXAMPLE"
	echo " ./tci-deploy-flogo.sh -targetEnvironment \"Staging\" -region \"us-west-2\" -username \"username@email.com\" -password \"Test56$\" -appName AbhiDeploymentTest_v1 -targetAppInstanceCount 2 -targetAppEndpointVisibility private -appAction deployApp"
	echo " ./tci-deploy-flogo.sh -sourceEnvironment \"Staging\" -targetEnvironment \"Production\" -region \"us-west-2\" -username \"username@email.com\" -password \"Test56$\" -appName AbhiDeploymentTest_v1 -targetAppInstanceCount 2 -targetAppEndpointVisibility private -appAction promoteApp"
	echo ""
}


############################################################
############################################################
# Main program                                             #
############################################################
############################################################

#Input Parameters
uninitializedVarDefValue="UNINITIALIZED"
sourceEnvironment=$uninitializedVarDefValue
targetEnvironment=$uninitializedVarDefValue
region=$uninitializedVarDefValue
username=$uninitializedVarDefValue
password=$uninitializedVarDefValue
appName=$uninitializedVarDefValue
targetAppInstanceCount=-1
targetAppEndpointVisibility=$uninitializedVarDefValue
appAction=$uninitializedVarDefValue
targetAppEndpointVisibilityDefValue="public"
appActionDefValue="deploy"

#Set Other Global Variables
appFound=false
targetAppFound=false

############################################################
# Process the input options. Add options as needed.        #
############################################################
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
	-h|\?) 
		# display Help
		Help
		exit
		;;
	-sourceEnvironment)
		sourceEnvironment="$2"
		shift # past argument
		shift # past value
		;;
	-targetEnvironment)
		targetEnvironment="$2"
		shift # past argument
		shift # past value
		;;
	-region)
      		region="$2"
		shift # past argument
		shift # past value
		;;
	-username)
      		username="$2"
		shift # past argument
		shift # past value
		;;
	-password)
      		password="$2"
		shift # past argument
		shift # past value
		;;
	-appName)
      		appName="$2"
		shift # past argument
		shift # past value
		;;
	-targetAppInstanceCount)
      		targetAppInstanceCount=$2
		shift # past argument
		shift # past value
		;;
	-targetAppEndpointVisibility)
      		targetAppEndpointVisibility="$2"
		shift # past argument
		shift # past value
		;;
	-appAction)
      		appAction="$2"
		shift # past argument
		shift # past value
		;;
	-default)
		DEFAULT=YES
		shift # past argument
		;;
	-*|--*)
		echo "Unknown option $1"
		exit 1
		;;
	*)
		POSITIONAL_ARGS+=("$1") # save positional arg
		shift # past argument
      		;;
  esac
done

uname=$(uname);
echo "Identifying OS....."
case "$uname" in
    (*Linux*) os='linux'; echo "Linux"; ;;
    (*Darwin*) os='darwin'; echo "Darwin"; ;;
    (*CYGWIN*) os='cygwin'; echo "Cygwin"; ;;
    (*) echo 'error: unsupported platform.'; exit 2; ;;
esac;


echo "Target TCI Organization Name: [$targetEnvironment]"
echo "Region: [$region]"
echo "User Name: [$username]"
echo "Password: [$password]"
echo "App Name: [$appName]"
echo "App Instance Count: [$targetAppInstanceCount]"
echo "Target App Endpoint Visibility: [$targetAppEndpointVisibility]"
echo "App Action [$appAction]"

###
#Update dependent variables
###
promoteAppName=${appName}_promote
targetAppDirName=${appName/_//}

#targetEnvironmentLowerCase=${targetEnvironment,,}
targetEnvironmentLowerCase=`echo $(tr '[:upper:]' '[:lower:]' <<< "$targetEnvironment")`

propertiesFileFullName="${propertyFileRootDir}${appName}.${targetEnvironmentLowerCase}.properties"
targetAppDirFullName="${flogoAppArtifactRootDir}${targetAppDirName}"
 
echo "Properties File Full Name: $propertiesFileFullName"
echo "Target App Directory Full Name: $targetAppDirFullName"

###
# Functions
###
#function prints colored text
function print_style () {

    if [ "$2" == "info" ] ; then
        COLOR="43m";
    elif [ "$2" == "success" ] ; then
        COLOR="92m";
    elif [ "$2" == "warning" ] ; then
        COLOR="93m";
    elif [ "$2" == "error" ] ; then
        COLOR="91m";
    else #default color
        COLOR="0m";
    fi

    STARTCOLOR="\e[$COLOR";
    ENDCOLOR="\e[0m";

    printf "$STARTCOLOR%b$ENDCOLOR" "$1\n";
}

function logout()
{
    echo ''
    echo '================== Logging Out =================='
	echo ''
	echo 'Attempting to logout first, in case there is an older login for another account'
	result=`${tibcliExe} logout 2>&1`
	
    	if [[ "$result" =~ "User logged out successfully" ]]
    	then
        	echo "$result"
    	else
        	echo "$result"
		exit 1
    	fi

    	echo '==============================================='
}

function login()
{
	local localEnvironment=$1
	echo ''
	echo '================== Logging In =================='
	echo ''
	 
	echo 'Logging into organization ' $localEnvironment ':' $region

	result=`${tibcliExe} login -u "$username" -p "$password" -o $localEnvironment -r $region 2>&1`
	
    	if [[ "$result" =~ "You've successfully logged into organization:" ]]
    	then
        	echo "$result"
    	else
		echo "$result"
        	exit 1
    	fi
	
    	echo '==============================================='
}

function checkAppExistence()
{
	local localAppName=$1
	local localEnvironment=$2
	echo ''
	echo "================== Check App Existence in $localEnvironment  =================="
	echo ''

        echo "Check if app $localAppName is deployed in organization $localEnvironment"

        result=`${tibcliExe} app detail $localAppName 2>&1`

	#echo $result

    	if [[ $result =~ "Error: App '$localAppName' not found in current user apps" ]]
    	then
	        echo "App not found."
        	appFound=false
	else
		echo "App Found"
		appFound=true
	fi

    	echo '==============================================='
}
function getAppStatus()
{
	local localAppName=$1
	local localEnvironment=$2
	
	echo ''
    	echo '================== Check App Status =================='
	echo ''
	 
	if($targetAppFound)
	then
		echo "Getting the status of App $localAppName in organization $localEnvironment"

                print_style "  NOTE: The app status command only returns once the current action against the app completes. This may take longer for apps with many instances." "info"
		print_style "        Press enter if you believe the command has completed and the script is not responding. It will not affect the execution of the script." "info"
		
		result=`${tibcliExe} app status $localAppName 2>&1`
		if [[ $? -eq 0 ]]
		then
			echo ''
			echo 'Command Completed Successfully'
			echo ''
		else
			echo "$result"
			exit 1
		fi	##ENDS - Exit code of get app status
	else
		echo "App $localAppName not found in organization $localEnvironment"
	fi
	
    	echo '==============================================='	
}

function printAppDetail
{
	local localAppName=$1
	local localMessage=$2
	local localEnvironment=$3
	
    	echo ''
    	echo "================== Print App Detail for App $localAppName - $localMessage =================="
	echo ''
	 
	if($targetAppFound)
	then
		result=`${tibcliExe} app detail $localAppName 2>&1`
			
		if [[ $? -eq 0 ]]
		then
			echo "$result"
			echo 'App Detail printed successfully.'
		else
			print_style "Error Occurred when printing app detail." "error"
			print_style "$result" "error"
			exit 1
		fi
	else
		echo "App $localAppName not found in organization $localEnvironment. Nothing to print."
	fi
	
    echo '==============================================='
}

function deleteApp
{
	local localAppName=$1
	local localEnvironment=$2

	echo ''
	echo '================== Deleting App =================='
	echo ''

	checkAppExistence $localAppName $localEnvironment

	if($appFound)
	then
		echo "Deleting App $localAppName from organization $localEnvironment"
		result=`${tibcliExe} app delete -f $localAppName 2>&1`
		if [[ $? -eq 0 ]]
		then
			echo "$result"
			echo 'App Deleted successfully.'
		else
			print_style "Error Occurred when deleting the app." "error"
			print_style "$result" "error"

			ignoreErrorRegExPatt="Error while deleting the application encrypted properties from privacy service"
                        if [[ "$result" =~ $ignoreErrorRegExPatt ]]
			then
				echo "Known Issue. Not Exiting."	
			else
				exit 1
			fi
		fi
	else
		echo "App not found. No Need to delete."
	fi
	echo '==============================================='
}

function copyApp
{
	local localAppName=$1
	local localPromoteAppName=$2
	local localSourceEnvironment=$3
	local localTargetEnvironment=$4

    	echo ''
    	echo '================== Copy App =================='
	echo ''

        if [[ "$targetAppFound" = true ]]
        then
                echo "Copying App $localAppName from organization $localSourceEnvironment to $localPromoteAppName in organization $localTargetEnvironment"

                result=`${tibcliExe} app copy --targetOrg $localTargetEnvironment --impose $localAppName $localPromoteAppName 2>&1`

                if [[ $? -eq 0 ]]
                then
                        echo ''
                        echo "$result"
                        echo ''
                else
                        echo "$result"
                        exit 1
                fi

        else
                echo "Copying App $localAppName from organization $localSourceEnvironment to organization $localTargetEnvironment"

                result=`${tibcliExe} app copy --targetOrg $localTargetEnvironment --impose $localAppName $localAppName 2>&1`

                if [[ $? -eq 0 ]]
                then
                        echo ''
                        echo "$result"
                        echo ''
                else
                        echo "$result"
                        exit 1
                fi
        fi


}

function updateAppVariables
{
	local localAppName=$1
	local localPromoteAppName=$2
	local localTargetEnvironment=$3

    	echo ''
    	echo '================== Update App Variables =================='
	echo ''

	localTargetAppName= 
	#Override targetAppName
        if [[ "$targetAppFound" = true ]]
        then

		localTargetAppName=$localPromoteAppName
	else
		localTargetAppName=$localAppName
	fi

        echo "Configuring App Varibles for $localTargetAppName in organization $localTargetEnvironment using file $propertiesFileFullName"

        result=`${tibcliExe} app configure --propfile $propertiesFileFullName --impose $localTargetAppName 2>&1`

        if [[ $? -eq 0 ]]
        then
	        echo ''
                echo "$result"
                echo ''
        else
                echo "$result"
                exit 1
        fi
}

function replaceApp
{
        local localAppName=$1
        local localPromoteAppName=$2
        local localTargetEnvironment=$3
        
        echo ''
        echo '================== Replace App =================='
        echo ''
        
        if [[ "$targetAppFound" = true ]]
        then
                echo "Replacing App $localAppName from $localPromoteAppName in organization $localTargetEnvironment"
                
                result=`${tibcliExe} app replace -i  $localPromoteAppName $localAppName 2>&1`

                if [[ $? -eq 0 ]]
                then
                        echo ''
                        echo "$result"
                        echo ''
                else
                        echo "$result"
                        exit 1
                fi

                deleteApp $localPromoteAppName $localTargetEnvironment

        else    
                echo "No action required."
        fi
}


function deployApp
{
	local localAppName=$1
	local localEnvironment=$2
	
    	echo ''
    	echo '================== Deploy App =================='
	echo ''

	pushd $targetAppDirFullName
	#cp $targetAppDirFullName/manifest.json .
	#cp $targetAppDirFullName/flogo.json .
	
	if [[ "$targetAppFound" = true ]]
	then
		echo "Deploying App $promoteAppName to organization $localEnvironment"
		
		result=`${tibcliExe} app push -p $propertiesFileFullName 0 $promoteAppName 2>&1`

		if [[ $? -eq 0 ]]
		then
			echo ''
			echo "$result"
			echo ''
		else
			echo "$result"
			exit 1
		fi
		
		result=`${tibcliExe} app replace -i  $promoteAppName $localAppName 2>&1`

		if [[ $? -eq 0 ]]
		then
			echo ''
			echo "$result"
			echo ''
		else
			echo "$result"
			exit 1
		fi	
		
		deleteApp $promoteAppName $localEnvironment
		
	else
		echo "Deploying App $localAppName to organization $localEnvironment"
		result=`${tibcliExe} app push -p $propertiesFileFullName 0 $localAppName 2>&1`

		if [[ $? -eq 0 ]]
		then
			echo ''
			echo "$result"
			echo ''
		else
			echo "$result"
			exit 1
		fi		
	fi
	popd
	
    	echo '==============================================='
}

function updateAppAttributes()
{
	local localAppName=$1
	local localEnvironment=$2
	local localMaxRetryCount=3
	
    	echo ''
	echo '================== Updating App -  Scaling, Status and Visibility =================='
	echo ''
	 
	if [[ "$targetAppFound" = true ]]
	then

	  #IC=Instance Count
	  foundIC=false
	  #DS=Deployment Stage
	  foundDS=false
	  #EV=Endpoint Visibility
	  foundEV=false
	  result=			  
	  for (( c=1; c<=$localMaxRetryCount; c++ ))
	  do
	    #echo [$foundIC]
	    echo "Update App Attributes Iteration: [$c]"

	    appDetail=`${tibcliExe} app detail $localAppName 2>&1`
	    echo "App Detail......"
	    echo $appDetail
	    echo "........"

	    if [[ "$foundIC" = false ]]
	    then	
		
		scaleUp=false
		
		#Scale Up Or Not
		echo ''
		echo 'Checking App Instance Count.....'
		echo ''
		
		#echo "$appDetail"	

	        regexPat='Actual Instance.*'
		if [[ "$appDetail" =~ $regexPat ]]; then foundIC=true; else foundIC=false; fi

		#echo "***"
		#echo "Bash Match is: ${BASH_REMATCH[0]}"
	    	#echo "***"
	
		if [[ "$foundIC" = true ]]
		then
			actualInstanceCount=`echo "${BASH_REMATCH[0]}" | head -1`
		else
			actualInstanceCount="Not Found: -1"
		fi
		
		#echo "RegEx Match Output is:  $actualInstanceCount"
					
	    	actualInstanceCount=`echo $actualInstanceCount | cut -d ":" -f 2 | tr -d " "`
		
		regexInt='^[+-]?[0-9]+$'
		
		if [[ "$actualInstanceCount" =~ $regexInt ]]
		then
			echo "Actual Instance Count is: [$actualInstanceCount]"
			if [[ $actualInstanceCount -ge $targetAppInstanceCount ]]
			then
				echo "Actual instance count matches (or is higher than the) target instance count of: [$targetAppInstanceCount]"	
				echo 'No Action Required.'				
			else
				echo 'Actual instance count is lower than target instance count. Scaling up.'
				scaleUp=true
			fi ##ENDS - If actualInstanceCount > targetAppInstanceCount			
		else
			echo "Actual Instance Count is not a number: [$actualInstanceCount]. Attempt Scaling up"
			scaleUp=true
		fi ##ENDS - If actualInstanceCount is a number
		
		if [[ "$scaleUp" = true ]]
		then
			echo "Scaling App $localAppName in organization $localEnvironment"

			result=`${tibcliExe} app scaleto $targetAppInstanceCount $localAppName 2>&1`
			
			if [[ $? -eq 0 ]]
			then
				echo "$result"
				echo 'App Instances Updated (Scaled) Successfully.'
			else
				echo 'Error Occurred when updating (Scaling) App Instances.'				
				echo "$result"
				foundIC=false

				if [[ $c -eq $localMaxRetryCount ]]
				then
					exit 1
					echo "Exiting."
				else
					echo "Script will attempt to update app instances in next iteration."
				fi
			fi						
		fi ##ENDS - if($ScaleUp)
	    else
		echo "Instance Count is already updated. No Action Required"
	    fi ##ENDS - if [[ $foundIC ]]
	    
		if [[ "$foundDS" = false ]]
		then
			##Deployment Stage
			echo ''
			echo 'Checking App Deployment Stage.....'		
			echo ''
		
        		regexPat='Deployment Stage:.*'
        		if [[ "$appDetail" =~ $regexPat ]]; then foundDS=true; else foundDS=false; fi

                	#echo "***"
		        #echo "Bash Match is: ${BASH_REMATCH[0]}"
                	#echo "***"
		
			if [[ "$foundDS" = true ]]
			then
				deploymentStage=`echo "${BASH_REMATCH[0]}" | head -1`
				echo "RegEx Match Output is:  $deploymentStage"
			
				deploymentStage=`echo $deploymentStage | cut -d ":" -f 2 | tr -d " "`
				echo "Deployment Stage is: [$deploymentStage]"
			
				if [[ "$deploymentStage" = "draft" ]]
				then
					echo "Setting the stage to Live for App $localAppName in organization $localEnvironment"
				
					result=`${tibcliExe} app update -d "live" --impose $localAppName 2>&1`
					if [[ $? -eq 0 ]]
					then
						echo 'Deployment Stage Updated Successfully.'
					else
						echo 'Error Occurred when updating Deployment Stage.'				
						echo "$result"
						foundDS=false

						if [[ $c -eq $localMaxRetryCount ]]
						then
							exit 1
							echo "Exiting."
						else
							echo "Script will attempt to update app deployment stage in next iteration."
						fi
					fi	##ENDS - Exit code of set stage to live.	
				else
					echo 'No Action Required.'
				fi ##ENDS - if(deployment stage draft)

			else
				echo 'Deployment Stage Info not found for the app.'
			fi ##ENDS - If found deployment stage info.
		else
			echo "Deployment Stage is already handled. No Action Required"
		fi ##ENDS - if [[ $foundDS ]]	    
		
		if [[ "$foundEV" = false ]]
		then
			##Endpoint Visibility - Public or Private
			echo ''
			echo 'Checking App Endpoint Visibility.....'
			echo ''		

			regexPat='Endpoint:.*'
			if [[ "$appDetail" =~ $regexPat ]]; then foundEV=true; else foundEV=false; fi

			#echo "***"
			#echo "Bash Match is: ${BASH_REMATCH[0]}"
			#echo "***"

		
            		if [[ "$foundEV" = true ]]
            		then		
                
				appEndpointVisibility=`echo "${BASH_REMATCH[0]}" | head -1`
                		echo "RegEx Match Output is:  $appEndpointVisibility"
				               
				appEndpointVisibility=`echo $appEndpointVisibility | cut -d ":" -f 2- | tr -d " "`
		                echo "Endpoint is: [$appEndpointVisibility]"
				
				regexPatPublic='https://integration.cloud.tibcoapps.com.*'
				regexPatNone='N/A.*'
				
				if [[ "$appEndpointVisibility" =~ $regexPatPublic ]] 
				then 
					appEndpointVisibility="public" 
				elif [[ "$appEndpointVisibility" =~ $regexPatNone ]] 
				then
					appEndpointVisibility="N/A"
				else
					appEndpointVisibility="private"
				fi
			
				echo "Current App Endpoint Visibility is: [ $appEndpointVisibility ]"
				
				if [[ "$targetAppEndpointVisibility" == "$appEndpointVisibility" ]] 
				then
					echo 'Current Endpoint Visibility matches Target Endpoint Visibility.'
					echo 'No Action Required.'
				elif [[ "$appEndpointVisibility" == "N/A" ]]
				then
					echo 'There is no app endpoint for the app. No action required.'					
				else
					echo "Setting the Endpoint Visibility to $targetAppEndpointVisibility for App $localAppName in organization $localEnvironment"

					result=`${tibcliExe} app update --visibility $targetAppEndpointVisibility --impose $localAppName 2>&1`
					if [[ $? -eq 0 ]]
					then
							echo 'Endpoint Visibility Updated Successfully.'
					else
							echo 'Error Occurred when updating Endpoint Visibility.'
							echo "$result"
							foundEV=false

							if [[ $c -eq $localMaxRetryCount ]]
							then
								exit 1
								echo "Exiting."
							else
								echo "Script will attempt to update app endpoint visibility in next iteration."
							fi
					fi      ##ENDS - Exit code of set endpoint visibility.
									
				fi ##ENDS - if(current endpoint visibility matches target EV)
			else
				echo 'App Endpoint Visibility Info not found.'
			fi ##ENDS - If found visibility info.	
		else
			echo "Endpoint Visibility is already handled. No Action Required"
		fi ##ENDS - if [[ $foundEV ]]	    

		if [[ "$foundIC" = true && "$foundDS" = true && "$foundEV" = true ]]
		then
			echo "All App Attributes have been handled in [$c] iteration(s)."
			break;
		fi
	  done ##ENDS - for (( c=1; c<=3; c++ ))
	  echo "All App Attributes have been successfully updated"
	fi ##ENDS - if($targetAppFound)
}

if [[ "$appAction" == "deployApp" ]]
then
	logout
	login $targetEnvironment
	checkAppExistence $appName $targetEnvironment
	targetAppFound=$appFound
	printAppDetail $appName "Before Deployment" $targetEnvironment
	deleteApp $promoteAppName $targetEnvironment
	deployApp $appName $targetEnvironment
	getAppStatus $appName $targetEnvironment
	updateAppAttributes $appName $targetEnvironment
	printAppDetail $appName "After Deployment" $targetEnvironment
	logout
elif [[ "$appAction" == "promoteApp" ]]
then
	echo "*****"
	echo "***** Promoting app from $sourceEnvironment to $targetEnvironment"
	echo "*****"
	logout
	login $targetEnvironment
	deleteApp $promoteAppName $targetEnvironment
	checkAppExistence $appName $targetEnvironment
	targetAppFound=$appFound
	printAppDetail $appName "Before Deployment" $targetEnvironment
	logout

	echo "*****"
	echo "***** Copying App"
	echo "*****"
	login $sourceEnvironment
	copyApp $appName $promoteAppName $sourceEnvironment $targetEnvironment
	logout

	echo "*****"
	echo "***** Updating app variables, replacing app and updating app attributes"
	echo "*****"
	login $targetEnvironment
	updateAppVariables $appName $promoteAppName $targetEnvironment
	replaceApp $appName $promoteAppName $targetEnvironment
	getAppStatus $appName $targetEnvironment
	updateAppAttributes $appName $targetEnvironment
	printAppDetail $appName "After Deployment" $targetEnvironment
	logout
	
elif [[ "$appAction" == "updateAppAttributes" ]]
then
	logout
	login $targetEnvironment
	checkAppExistence $appName $targetEnvironment
	targetAppFound=$appFound
	printAppDetail $appName "Before Attribute Updates" $targetEnvironment
	updateAppAttributes $appName $targetEnvironment
	printAppDetail $appName "After Attribute Updates" $targetEnvironment
	logout
else
	print_style "Invalid -appAction $appAction." "error"
fi
