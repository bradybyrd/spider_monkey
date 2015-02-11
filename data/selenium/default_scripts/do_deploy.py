"""
p:
  name: Package Path
n:
  name: Package Name
t:
  name: Good Targets
"""

# System Jython libraries
import sys
import string as s
import getopt
import re
import time
import random
import os
import string

# BladeLogic class libraries
import bladelogic.cli.CLI as blcli
from com.bladelogic.client import BRProfile

# Create the object jli
jli = blcli.CLI()
jli.setAppServerHost("10.0.1.50")
jli.setLoginConfigFileName("/usr/nsh/br/.bladelogic/.user/user_info.data")
jli.connect() 

DEBUG = 0
DEBUG_HI = 0

def usage():
    print "\n    Usage: " + progName + " -f <instruction_file> [-r <role>]"
    print "      -r <role>: Name of the role as which the framework should execute."
    sys.exit(1)

def printInfo(text):
    sys.stdout.write("INFO: %s\n" % (text))

def printDebug(text):
    if(DEBUG):
        sys.stdout.write("DEBUG: %s\n" % (text))

def printDebugHigh(text):
    if(DEBUG_HI):
        sys.stdout.write("HIGH DEBUG: %s\n" % (text))

def printError(error):
    sys.stdout.write("\n\nERROR: %s\n\n" % (error))

def checkJobRunForErrors(jobRunKey):
    printInfo("Checking job run for errors.")
    jobErrorsResult = jli.run(['JobRun','getJobRunHadErrors',jobRunKey])

    if not (jobErrorsResult.success()):
        printError("Could not determine job run errors.")
        return "RUNERROR"
    else:
        return str(jobErrorsResult.returnValue)



def executeDeployJob(deployJobKey):
    printInfo("Executing deploy job %s" % deployJobKey)

    jobRunResult = jli.run(['DeployJob','executeJobAndWait',str(deployJobKey)])
    if not (jobRunResult.success()):
        printError("Deploy job could not be executed.  Exiting.")
        return 0
    else:
        jobRunKey = str(jobRunResult.returnValue)
        return jobRunKey



def modifyDeployJob(key,targets):
    printDebug("ModifyDeployJob: %s, %s:" % (key,targets))
    err_count = 0
    jobDBKeyStatus = jli.run(['Job','clearTargetServers',key])
    if not jobDBKeyStatus.success():
        printError("Unable to clear targets on deploy job")
        return "ERROR"
    else:
        jobDBKey = jobDBKeyStatus.returnValue
        printDebug("Adding Servers to job %s" % jobDBKey)
        printDebug("Servers are %s" % targets)
        if len(targets) > 1:
            for i in targets:
                printInfo("Modifying job %s" % jobDBKey)
                printInfo("Adding server %s to deploy job" % i)
                addTargetStatus = jli.run(['Job','addTargetServer',str(jobDBKey),i])
                if not addTargetStatus.success():
                    printError("Unable to add target %s to deploy job" % i)
                    printDebug("BLCLI Error: %s" % addTargetStatus.getError())
                    err_count = err_count + 1
                else:
                    printDebug("Setting new key: %s" % addTargetStatus.returnValue)
                    jobDBKey = addTargetStatus.returnValue
        elif len(targets) == 1:
            printInfo("Modifying job %s" % jobDBKey)
            printInfo("Adding server %s to deploy job" % str(targets[0]))
            addTargetStatus = jli.run(['Job','addTargetServer',str(jobDBKey),str(targets[0])])
            if not addTargetStatus.success():
                printError("Unable to add target %s to deploy job" % str(targets[0]))
                printDebug("BLCLI Error: %s" % addTargetStatus.getError())
                err_count = err_count + 1
            else:
                jobDBKey = addTargetStatus.returnValue

    if err_count > 0:
        printError("Check deploy job for missing targets")
        return "ERROR"
    else:
        return jobDBKey



def createDeployJob(name,groupId,pkgKey,target):
    printInfo("Creating deploy job %s..." % name)
    add_server_status = []
    addServersToJobs = 0
    if len(target) == 1:
        createJobResult = jli.run(['DeployJob','createDeployJob',name,str(groupId),pkgKey,str(target[0]),'true','true','false'])
        if not (createJobResult.success()):
            printError("Could not create job %s.  Error: %s" % (name,createJobResult.getError()))
            return 0
        else:
            addServersToJobs = addServersToJobs + 1
            jobDBKey = createJobResult.returnValue
    elif len(target) > 1:
        x = target.pop(0)
        createJobResult = jli.run(['DeployJob','createDeployJob',name,str(groupId),pkgKey,x,'true','true','false'])
        if not (createJobResult.success()):
            printError("Could not create job %s. Error: %s" % (name,createJobResult.getError()))
            return 0
        else:
            jobDBKey = createJobResult.returnValue
            printDebug("createDeployJob jobDBKey is: %s" % jobDBKey)
            for x1 in target:
                printDebug("createDeployJob x1 is: %s" % x1)
                addTargetServer = jli.run(['Job','addTargetServer',str(jobDBKey),x1])
                if not addTargetServer.success():
                    printError("Unable to add server %s to Deploy Job %s" % (x1,jobDBKey))
                    printDebug("Add Servers to Jobs failed with error: %s" % addTargetServer.getError())
                else:
                    printInfo("Added server %s to Deploy Job %s" % (x1,name))
                    jobDBKey = addTargetServer.returnValue
                    addServersToJobs = addServersToJobs + 1

    else:
        printError("Number of targets passed is incorrect")
        return 0

    if addServersToJobs == 0:
        printError("Unable to add all target servers to job.  Check logs.")
        return 0
    else:
        printInfo("Job %s created successfully." % name)
        return str(jobDBKey)



def createGroup(path,grpType):
    # Iterate through the tree to create the groups
    pathList = path.split("/")
    newPath = ""

    # FIX: Set root group ID
    parentGrpId = jli.run([grpType+'Group','groupNameToId','/']).returnValue

    for group in pathList:

        if(group == ""):
            continue

        newPath = "%s/%s" % (newPath,group)
        printInfo("Checking for group %s" % newPath)
        
        # Check to see if group exists
        groupResult = jli.run([grpType+'Group','groupNameToId',newPath])

        if not groupResult.success():
            printDebug("%s group %s not found. Creating %s group." % (grpType,newPath,newPath))
            grpCreate = jli.run([grpType+'Group','create'+grpType+'Group',group,str(parentGrpId)])

            if not (grpCreate.success()):
                printError("%s group creation failed: %s" % (grpType,str(grpCreate.getError())))
                return 0
            else:
                parentGrpId = grpCreate.returnValue
        else:
            # If the group already exists, then it's the parent
            # of the next group
            parentGrpId = groupResult.returnValue

    # Return the last group ID
    return parentGrpId



def doDeploy(path,name,target):
    printInfo(" ****** Third-party package deployment beginning ****** \n")

    # See if a job exists with the same name and path for the target
    # in question

    # Do not name third-party package deploy jobs with the same naming
    # convention used for code deploy jobs.
    deployJobName = name

    jobExistsResult = jli.run(['DeployJob','getDBKeyByGroupAndName',path,deployJobName])

    if not jobExistsResult.success():
        # If not, then find the package and create the job
        printDebug("Retrieving BLPackage key.")
        packageKeyResult = jli.run(['BlPackage','getDBKeyByGroupAndName',path,name])

        if not packageKeyResult.success():
            printError("Error retrieving BLPackage key: %s" % packageKeyResult.getError())
            return ("Error retrieving BLPackage key: %s" % packageKeyResult.getError())

        pkgKey = str(packageKeyResult.returnValue)
        printDebug("Package key: %s" % pkgKey)

        # Ensure the job group exists
        printDebug("Checking existence of job group.")
        jobGroupResult = jli.run(['JobGroup','groupNameToId',path])

        # FIX: Does this account for a group to which we don't have
        # authorizations to write?
        if not jobGroupResult.success():
            printDebug("Job group not found. Creating new group.")
            jobGroupId = createGroup(path,'Job')
            if jobGroupId == 0:
                printError("Unable to create Job group %s.  Check error logs." % path)
                return ("Unable to create Job group %s.  Check error logs." % path)
        else:
            jobGroupId = jobGroupResult.returnValue

        # Create the job itself
        deployJobKey = createDeployJob(deployJobName,jobGroupId,pkgKey,target)
        if deployJobKey == 0:
            return 0
    else:
        # Job already exists.  Clear out the old targets and add new targets.
        deployJobKeyStart = str(jobExistsResult.returnValue)
        deployJobKey = modifyDeployJob(deployJobKeyStart,target)
        if deployJobKey == "ERROR":
            printError("Modification of deploy job %s failed.  Check the logs..." % name)
            return 0

    # Execute the job
    jobRunKey = executeDeployJob(deployJobKey)
    if jobRunKey != 0:
        # Check job for errors
        hadErrors = checkJobRunForErrors(jobRunKey)
        printDebug("Job error result: "+hadErrors)

    # If the job had errors, then exit out
    if hadErrors == "RUNERROR":
        printError("Unable to run job run error check")
        return 0
    elif(hadErrors != "0"):
        printError("Error: Job %s failed during execution.  Please check logs and re-execute deployment." % deployJobName)
        return 0

    # Job completed successfully; return to main script
    printInfo("Finished executing third-party package deployment of %s" % name)
    printInfo(" ****** Third-party package deployment complete ****** \n")

    # If we get here, the entire doDeploy mothod finished properly.
    return 1

# END def doDeploy



try:
        opts, args = getopt.getopt(sys.argv[1:], "p:n:t:")
except getopt.GetoptError:
        usage()

packagePath = ''
packageName = ''
good_targets = ''

for opt, arg in opts:
        if opt == '-p':
                packagePath = arg
        elif opt == '-n':
                packageName = arg
        elif opt == '-t':
                good_targets = arg

doDeploy(packagePath,packageName,good_targets)
