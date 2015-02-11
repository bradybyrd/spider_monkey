"""
v:
  name: Vendor
p:
  name: OS Platform 
t:
  name: Tier 
n:
  name: Application Name 
r:
  name: Application Version 
s:
  name: Sibling Version 
c:
  name: Subversion source
i:
  name: Subversion repository 
e:
  name: Uploads (must be comma-separated)
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
import sysexec
import bladelogic.cli.CLI as blcli
from com.bladelogic.client import BRProfile

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

def findGroupId(grpPath,grpType):
    nameSpace = grpType+"Group"
    grpIdResult = jli.run([nameSpace,'groupNameToId',grpPath])
    if not (grpIdResult.success()):
        printDebug(grpType+" group at '"+grpPath+"' not found.")
        return "false"

    return grpIdResult.returnValue

def getLatestBLVersion(vendor,appName,depTier,appVersion,platform):
    printInfo("Querying for latest template version.")
    # Get the BL group path (as /Application Deployments/App Name/App Version)
    grpPath = getGrpPath(appName,appVersion)

    # First, pull the depot group ID
    depotGrpId = findGroupId(grpPath,"Depot")
    
    if(depotGrpId == "false"):
        printInfo("No depot group found.  Sibling version is 0.")
        return 0

    # Set the initial version as 0
    currentVersionNum = 1
    # Get all items in the group
    listResult = jli.run(['DepotObject','findAllDepotObjectsByGroupId',str(depotGrpId),'false'])
    if not listResult.success():
        printError("Failed to pull depot object list: "+str(listResult.getError()))
        return "ERROR"
    
    objlist = listResult.returnValue
    #Get the latest version (sibVersion) of the package found in the depot group.
    #This assumes the file's name is NAME_VERSION_SIBVERSION
    baseName = getObjBaseName(vendor,appName,depTier,appVersion,platform)
    for depotObject in objlist:
        # Check the object type
        # UNRELEASED FUNCTIONALITY!
        type = depotObject.getType()
        name = depotObject.getName()
        #printDebug("Old BLPackage name: "+name)
        # Check to see if it's an old template
        if re.search(baseName,name):
            basePrev = re.sub(baseName,'',name)
            crud,baseVer = basePrev.split('PREV')
            if (baseVer.isnumeric()) and (baseVer != ''):
                #printDebug("Checking version "+str(baseVer)+" against "+str(currentVersionNum))
                if int(baseVer) > int(currentVersionNum):
                    #printDebug("Using version "+str(baseVer))
                    #Return SIBVERSION from NAME_VERSION_SIBVERSION
                    currentVersionNum = baseVer

    return str(currentVersionNum)
                        
def getGrpPath(appName,appVersion):
    return('/Application Deployments/'+s.upper(appName)+'/'+s.upper(appVersion))

def checkDependencies(action,grpPath):
    # Check that the component group exists (for creating the package)
    if(action == 'APP_PACKAGE'):
        grpExistsResult = jli.run(['TemplateGroup','groupNameToDBKey',grpPath])
        if not grpExistsResult.success():
            printInfo("Could not find template group %s. Creating group." % grpPath)
            status = createGroup(grpPath,'Template')
            if status == 0:
                printError("Unable to create template groups.  Exiting action. Check logs.")
                return 0 
            else:
                printInfo("Created template group %s." % grpPath)
        else:
            printDebug("Template group %s found." % grpPath)

    # Check that the depot group exists (for creating the package)
    if(action == 'APP_PACKAGE'):
        grpExistsResult = jli.run(['DepotGroup','groupNameToDBKey',grpPath])
        if not grpExistsResult.success():
            printError("Could not find depot group %s.  Creating group." % grpPath)
            status = createGroup(grpPath,'Depot')
            if status == 0:
                printError("Unable to create depot groups.  Exiting action. Check logs.")
                return 0 
        else:
            printDebug("Depot group %s found." % grpPath)

    printInfo("Completed dependency check.")
    return 1

def checkPropClassExists(propPath):
    printDebug("Checking for existence of property class %s." % propPath)
    prpExistsResult = jli.run(['PropertyClass','isPropertyDefined',propPath,'NAME'])
    if (prpExistsResult.success()):
        printInfo("Property class %s exists." % propPath)
        return "true"
    else:
        printInfo("Property class %s not found." % propPath)
        return "false"

def checkPropExists(propClassPath,propName):
    printInfo("Checking for existence of property %s in class %s" % (propName,propClassPath))
    prpExistsResult = jli.run(['PropertyClass','isPropertyDefined',propClassPath,propName])

    if not (prpExistsResult.success()):
        printError("Unable to check property status.  CLI command failed: %s" % str(prpExistsResult.getError()))
        return 0 

    result = str(prpExistsResult.returnValue)
    printDebug("Prop exists result: %s" % result)

    if(result == "1"):
        printInfo("Property %s found in class %s." % (propName,propClassPath))
        return "true"
    else:
        printInfo("Property %s not found in class %s" % (propName,propClassPath))
        return "false"

def createAppPropertyClassTree(vendor,platform,depTier,appName,appVersion,sibVer,numUploads):
    error = 0
    printInfo("Checking for property class existence.")
    basePropClass = BASE_PROPERTY_CLASS

    # Set up property class name
    appPropClassPath = "%s/%s/%s" % (basePropClass,appName,depTier)
    appVersPropClassPath = "%s/%s/%s" % (appPropClassPath,appVersion,platform)    

    # Every property class has a NAME property, so we'll check for that.
    propClassExists = checkPropClassExists(appVersPropClassPath)

    if propClassExists == "true":
        count = 1
    elif propClassExists == "false":
        header,classes = appVersPropClassPath.split('//SystemObject/')
        classList = classes.split('/')
        
        newClass = "Class://SystemObject"

        for subclass in classList:
            if subclass == "":
                continue

            nameClass = "%s/%s" % (newClass,subclass)
            classCheck = checkPropClassExists(nameClass)

            if classCheck == "false":
                printDebug("Unable to find class %s." % nameClass)
                printInfo("Creating new custom property class %s." % nameClass)
                createPropertyClassStatus = createPropertyClass(newClass,subclass)
                if createPropertyClassStatus == 0:
                    return 0
            else:
                printDebug("Class %s exists." % nameClass)

            newClass = nameClass
        count = 1
    
    while (count <= numUploads):
        propName = "BASEDIR_"+str(count)
        printDebug("Checking to see if property %s is defined in property class %s" % (propName,appVersPropClassPath))

        prpExists = checkPropExists(appVersPropClassPath,propName)

        if(prpExists == "true"):
            printDebug("Property %s already exists.  Skipping creation." % propName)
        else:
            status = createProperty(appVersPropClassPath,propName,"Primitive:/String")
            if status != 1:
                printError("Unable to create property %s in class %s\nExiting method createAppPropertyClassTree without finishing." % (propName,appVersPropClassPath))
                error = 1
            else:
                printInfo("Created property %s in class %s" % (propName,appVersPropClassPath))
        count = count + 1
        if error == 1:
            return 0
    # Done creating property classes
    if error == 0:
        return 1

def getTemplateGroupId(grpPath):
    templateGroupIdResult = jli.run(['TemplateGroup','groupNameToId',grpPath])
    if not (templateGroupIdResult.success()):
        printError("Failed to retrieve template group ID: %s" % str(templateGroupIdResult.getError()))
        return "ERROR"
    else:
        templateGroupId = templateGroupIdResult.returnValue
        return templateGroupId

def checkOutCode(source,repository,depTier):
    unique = random.randint(0,9999999)
    # In subversion, it is not possible to check out individual files,
    # so instead we shall check out the entire repository.
    printDebug("Checking out code from %s on %s" % (repository,source))

    # targetDir = "%s%s%s" % (BASE_PATH,str(repository),depTier)
    targetDir = "%s%s" % (BASE_PATH,os.path.basename(str(repository)))
    # repClean = "file://%s/%s" % (repository,depTier)
    repClean = "file://%s" % (repository)

    #fileOut = os.path.normpath("/tmp/svn_exec.nsh")
    fileOut = "/tmp/svn_exec.nsh_%s" % unique
    commandOut = "cd //%s \nnexec -i -e svn -q --non-interactive checkout %s %s\nexit $?\n" % (str(source),repClean,targetDir)
    printInfo("Creating temporary command execution file for SVN: %s" % fileOut)
    try:
        fsock = open(fileOut,"w")
        fsock.write(commandOut)
        fsock.close()
    except IOError:
        printError("Problem writing to file %s." % fileOut)
        return 0

    printInfo("Checking out files from SVN repository %s" % repository)
    checkoutCmd = ['nsh','-c',fileOut]

    coResult= sysexec.execv(checkoutCmd)
    if(coResult.isError()):
        printError("Could not check out code from source repository %s. Exiting" % repository)
        printError(coResult.getStdErr())
        status = 0
    else:
        printInfo("Code checked out successfully.")
        status = 1

    printInfo("Deleting temporary command execution file for SVN: %s" % fileOut)
#    os.remove(fileOut)

    return status

def getTmpBasePath(reposName):
    basePath = BASE_PATH

    if(reposName != ''):
        basePath = "%s%s" % (basePath,str(reposName))         
    return basePath

def checkTemplateExists(objName,grpId):
    exists = jli.run(['Template','findByGroupAndName',str(grpId),objName])
    if not exists.success():
        return 0
    else:
        return 1

def deleteTemplate(objName,grpName):
    status = jli.run(['Template','deleteTemplate',objName,grpName])
    if not status.success():
        printError("Unable to delete template %s/%s: %s" % (grpName,objName,status.getError()))
        return 0
    else:
        printInfo("Successfully deleted template %s/%s" % (grpName,objName))
        return 1
    
def createEmptyTemplate(templateName,templateGroupId,is_anon,is_match_all):
    # Create a template without any parts.
    templateCreateStatus = jli.run(['Template','createEmptyTemplate',templateName,str(templateGroupId),is_anon,is_match_all])
    if not templateCreateStatus.success():
        printError("Failed to create template: %s" % str(templateCreateStatus.getError()))
        return "ERROR"
    else:
        templateDBKey = templateCreateStatus.returnValue
        printInfo("Created template named %s with id %s" % (templateName,str(templateDBKey)))
        return str(templateDBKey)
    
def setCustomPropertyValue(propClass,propName,val):
    printInfo("Setting instance value for %s to %s." % (propName,val))
    valueSetResult = jli.run(['PropertyInstance','setOverriddenValue',propClass,propName,val])

    if not (valueSetResult.success()):
        printError("Could not set property instance value: %s" % str(valueSetResult.getError()))
        return 0
    else:
        printInfo("Finished setting instance value for %s to %s" % (propName,val))
        return 1
    
def createAppPropertyInstance(vendor,platform,depTier,appName,appVersion,host,assets,sibVer,baseDir):
    printInfo("Creating app property instance for application %s" % appName)
    appPropClass = "%s/%s/%s" % (BASE_PROPERTY_CLASS,appName,depTier)
    appVersPropClass = "%s/%s/%s/%s/%s" % (BASE_PROPERTY_CLASS,appName,depTier,appVersion,platform)

    #printDebug("Base class name: "+str(baseSvrProp))
    instanceName = [("RELEASE_%s_SOURCE" % sibVer)]
    for i in instanceName:
        classAndInstance = "%s/%s" % (appVersPropClass,i)
        # Create an instance (and check failure to see if it already exists)
        instanceResult = jli.run(['PropertyInstance','createInstance',appVersPropClass,i,i])
        if not (instanceResult.success()):
            if(re.search("already exists",str(instanceResult.getError()))):
                printInfo("Instance %s already exists." % sibVer)
            else:
                printError("Could not create property class instance: %s" % str(instanceResult.getError()))
                #return 0

        # Only set properties if an asset list was passed in
        if(assets != ""):
            # Loop through the assets and set the property values
            count = 1
            for asset in assets:
                # If baseDir is passed in, then override the asset value
                if(baseDir != ''):
                    asset = baseDir
            
                printDebug("Upload in this case: %s" % str(asset))
                propName = "BASEDIR_%s" % str(count)
            
                result = setCustomPropertyValue(classAndInstance,propName,asset)
                if result == 0:
                    printError("Unable to set property %s in class %s" % (propName,classAndInstance))
                    return 0
                else:
                    count = count + 1

    printInfo("Completed setting properties on instance %s" % classAndInstance)
    return 1

def setLocalTemplateParameter(templateName,templateGroup,propName,propDesc,propType,is_editable,is_required,default_value):
    setLocParamStat = jli.run(['Template','addLocalParameter',templateName,templateGroup,propName,propDesc,propType,is_editable,is_required,default_value])
    if not setLocParamStat.success():
        printError("Unable to set local template parameter: %s" % str(setLocParamStat.getError()))
        return 0
    else:
        return 1
        
def addUploadToTemplate(templateName,templateDBKey,templateGroupId,asset,isDir,index):

    # Set base property name
    baseDirPropName = "BASEDIR.BASEDIR_%s" % str(index)
    if asset == "*":
        #    assetBase = "??BASEDIR.%s/" % (baseDirPropName)
        assetPath = "??%s??" % (baseDirPropName)
    else:
        assetPath = "??%s??/%s" % (baseDirPropName,asset)
        
    # Add a new piece to the template
    if(isDir == "true"):
        printDebug("Adding directory to existing template.")
        templateResult = jli.run(['Template','addDirectoryPart',str(templateDBKey),assetPath,'false','false','false','true','true','false','false','false','true','true'])
        if not(templateResult.success()):
            printError("Failed to add directory part to template: %s" % templateResult.getError())
            return 0
        else:
            printDebug(" created successfully.")
            templateDBKey = templateResult.returnValue
    else:
        printDebug("Adding file to existing template.")
        templateResult = jli.run(['Template','addFilePart',str(templateDBKey),assetPath,'false','false','false','true','false','false','false','true','true'])
        if not(templateResult.success()):
            printError("Failed to add file part to template template: %s" % templateResult.getError())
            return 0
        else:
            printDebug("Template created successfully.")
            templateDBKey = templateResult.returnValue

    # Return the new template key
    return str(templateDBKey)

def setInstanceValue(templateName,grpName,instanceName,paramName,value):
    setValueStat = jli.run(['Template','setParameterInstanceOverriddenValue',templateName,grpName,instanceName,paramName,value])
    if not setValueStat.success():
        printError("Unable to set value in property instance: %s" % setValueStat.getError())
        return 0 
    else:
        printInfo("Set value %s in property instance %s." % (value,paramName))
        return 1
        
def doCreateComponent(server,templateKey,objName):
    printInfo("Discovering components for template.")
    printDebug("Creating discovery job for template")
    discoveryGroup = "/Application Deployments/Discovery Jobs"
    groupId = findGroupId(discoveryGroup,'Job')
    if groupId == "false":
        printInfo("Creating job folder for discovery")
        groupId = createGroup(discoveryGroup,'Job')

    jobCreateStatus = jli.run(['ComponentDiscoveryJob','createComponentDiscoveryJob',objName,str(groupId),str(templateKey),server])
    if not jobCreateStatus.success():
        printError("Unable to create discovery job for template %s" % objName)
        return 0
    else:
        printDebug("Suceeded in creating discovery job for template %s" % objName)
        jobDBKey = jobCreateStatus.returnValue
    jobRunStatus = jli.run(['ComponentDiscoveryJob','executeJobAndWait',str(jobDBKey)])
    if not jobRunStatus.success():
        printError("Unable to execute component discovery job: %s" % jobRunStatus.getError())
        return 0
    else:
        printInfo("Completed component discovery job creation and execution")
        return jobRunStatus.returnValue

def getComponentKey(server,templateKey,objName):
    serverId = jli.run(['Server','getServerIdByName',server]).returnValue
    printDebug("Server ID for %s is %s" % (server,serverId))
    componentKey = jli.run(['Component','getAllComponentKeysByTemplateKeyAndServerId',str(templateKey),str(serverId)])
    if not componentKey.success():
        printError("Unable to get component key from template %s" % objName)
        return 0
    else:
        return componentKey.returnValue

def doCreateBLPackage(objName,depotGroupId,componentKeyR):
    printInfo("Creating BLPackage from component %s" % componentKeyR)
    componentKey = string.rstrip(componentKeyR)
    packageResult = jli.run(['BlPackage','createPackageFromComponent',objName,str(depotGroupId),'false','false','true','true','false',str(componentKey)])
    if not(packageResult.success()):
        printError("Creating BLPackage %s failed: %s" % (objName,packageResult.getError()))
        return 0
    else:
        printDebug("Created BLPackage %s." % objName)
        return str(packageResult.returnValue)

def deleteCodeRepository(source,basePath):

    printDebug("Deleting "+basePath+".")
    deleteCmd = ['nexec',str(source),'rm','-rf',basePath]
    deleteResult= sysexec.execv(deleteCmd,timeout=15)

    if(deleteResult.isError()):
        printError("Could not delete temporary source tree at '"+basePath+"'.  Exiting.")
        printError(deleteResult.getStdErr())
        sys.exit(1)
    else:
        printInfo("Temporary code branch deleted successfully.")

def doPackage(vendor,platform,depTier,appName,appVersion,sibVer,source,repository,assets):
    printInfo(" ****** Package creation beginning ****** \n")
    templateKey = ''

    # Parse the asset list
    if len(assets) == 1 and '*' in assets:
        assetList = ['*']
    else:
        assetList = assets.split(',')

    if len(assetList) == 0:
        printError("There are no assets specified.  Check the control file.")
        return 0 

    # Set final result by adding 1 to the highest previous version unless
    # the version number is set by the control file.
    if sibVer == "":
        # Define our applciation code name
        currentVersion = getLatestBLVersion(vendor,appName,depTier,appVersion,platform)
        objVersion = int(currentVersion)+1
    else:
        objVersion = sibVer

    printInfo("Using base version of "+str(objVersion))

    # Create standardized group path
    grpPath = getGrpPath(appName,appVersion)

    # Ensure that our packaging location exists
    status = checkDependencies('APP_PACKAGE',grpPath)
    if status != 1:
        printError("Failed dependency check during doPackage method!")
        return 0
    else:
        printInfo("Completed dependency check for application packaging")

    # Get the name of the repository directory
    reposPathList = repository.split("/")
    reposName = reposPathList[len(reposPathList) - 1]

    # Create a property class for the application.  It should
    # have one BASE_DIR property for each asset in the package.

    # ADD A CHECK! -- Sung Koo
    createAppPropertyClassTreeStat = createAppPropertyClassTree(vendor,platform,depTier,appName,appVersion,objVersion,len(assetList))
    if createAppPropertyClassTreeStat != 1:
        printError("Error occured during creation of application property class tree.  Check logs...")
        return 0 

    # Get template group ID
    templateGroupId = getTemplateGroupId(grpPath)
    if templateGroupId == "ERROR":
        printError("Unable to find template group id.")
        return 0 

    # Get the depot group ID
    depotGroupIdResult = jli.run(['DepotGroup','groupNameToId',grpPath])
    if not (depotGroupIdResult.success()):
        printError("Failed to retrieve depot group ID: %s" % str(depotGroupIdResult.getError()))
        return 0
    else:
        depotGroupId = depotGroupIdResult.returnValue

    # Make sure we can communicate with the source server
    printDebug("Checking RSCD communication with %s" % source)
    # FIX: Come up with a way to test the source server via the application server
    command = ['nsh','-c','agentinfo ' + str(source)]
    agentinfo = sysexec.execv(command,timeout=10)
    if(agentinfo.isError()):
        printError("Could not communicate with source server "+source+".  Exiting.")
        printError(agentinfo.getStdErr())
        return 0 
        #sys.exit(1)
    else:
        printInfo("Source server %s found." % source)

    objName = "%s-%s-%s-%s-%s_PREV%s" % (vendor,appName,depTier,appVersion,platform,str(objVersion))

    # Check out the repository
    # FIX: Uncomment so we can talk to SVN when we've got it

    # Add Error Checking -- Sung Koo
    checkOutCodeStatus = checkOutCode(source,repository,depTier)
    if checkOutCodeStatus != 1:
        printError("Unable to check out code from SVN.  Check Logs.")
        return 0
    else:
        printInfo("Completed checking out code from SVN.")
    
    basePath = getTmpBasePath(reposName)
    isDirectory = "true"
    index = 0

    # Create an empty template and set the local property to reference 
    # the appropriate custom property class.
    localPropName = "BASEDIR"
    propType = "%s/%s/%s/%s/%s" % (BASE_PROPERTY_CLASS,appName,depTier,appVersion,platform)
    grpName = "/Application Deployments/%s/%s" % (appName,appVersion)

    findTemplate = checkTemplateExists(objName,templateGroupId)
    if findTemplate == 1:
        printInfo("Template %s/%s already exists.  Deleting..." % (grpName,objName))
        t_deleteStatus = deleteTemplate(objName,grpName)
        if t_deleteStatus != 1:
            return 1
    else:
        printInfo("Template %s does not exist." % objName)
        
    templateKey = createEmptyTemplate(objName,templateGroupId,'true','true')

    if templateKey == "ERROR":
        printError("Unable to create template %s.  Please check the logs." % objName)
        return 0

    # Create a property instance for paramaterized BLPackage collection
    createAppPropertyInstanceStatus = createAppPropertyInstance(vendor,platform,depTier,appName,appVersion,source,assetList,objVersion,basePath)
    if createAppPropertyInstanceStatus == 0:
        return 0

    #setLocalTemplateParameter(objName,grpName,localPropName,localPropName,propType,is_editable,is_required,'')
    setLocalTemplateParameterStatus = setLocalTemplateParameter(objName,grpName,localPropName,localPropName,propType,'true','false','')
    if setLocalTemplateParameterStatus != 1:
        return 0

    
    # SET INSTANCE FOR ENTIRE Template
    createParamStatus = jli.run(['Template','createParameterInstance',objName,grpPath,'CUSTOM_APPLICATION_PARAMETERS','CUSTOM_APPLICATION_PARAMETERS'])
    if not createParamStatus.success():
        printError("Unable to create parameter instance for template %s" % objName)
        return 0
    else:
        templateDBKey = jli.run(['Template','getDBKey']).returnValue
        templateKey = createParamStatus.returnValue
        
    # Count the number of assets and do some bulk property creation
    numUploads = len(assetList)

    for asset in assetList:
        # Index the assets for parameterization purposes
        index = index + 1
        
        # Check out the asset from SVN
        printInfo("Adding asset %s to package footprint." % asset)
        if asset == "*":
            # Insure asset existence
            # assetTypeCmd = ['runcmd','-NH','-h',str(source),'-e','test','-e',basePath+'/'+str(asset)]
            assetPath = "//%s%s" % (str(source),basePath)
        else:
            ### MODIFIED TO FIX DOUBLE ASSET MARKINGS  12/11/2006
            #assetPath = "//%s%s/%s" % (str(source),basePath,asset)
            assetPath = "//%s%s" % (str(source),basePath)

        assetCheckCmd = ['ls','-ld',assetPath]
        assetPathResult = sysexec.execv(assetCheckCmd,timeout=10)
        assetPathResultOut = assetPathResult.getStdOut()

        if assetPathResultOut == "" :
            printError("Could not find asset %s.  Exiting." % assetPath)
            printError(assetTypeResult.getStdErr())
        else:
            assetElements = assetPathResultOut.split()
            assetPerms = str(assetElements[0])
            assetType = assetPerms[0]

        # Check to see if asset is a directory
        if assetType == 'd':
            isDirectory = "true"
        else:
            isDirectory = "false"

        # Create a template for each asset with a parameterized path
        templateDBKey = addUploadToTemplate(objName,str(templateDBKey),templateGroupId,asset,isDirectory,index)
        if templateKey == 0:
            return 0

    # Set parameter instance association with class
    instanceName = "RELEASE_%s_SOURCE" % objVersion
    # paramName = "BASEDIR_%s" % index
    paramName = "BASEDIR"
    setValue = "%s/%s" % (propType,instanceName)
    setInstanceValueStatus = setInstanceValue(objName,grpPath,'CUSTOM_APPLICATION_PARAMETERS',paramName,setValue)
    if setInstanceValueStatus != 1:
        return 0
        
    # Finished building template; let's discover the component
    # and create a BLPackage from it
    discoveryJobKey = doCreateComponent(source,templateDBKey,objName)
    printDebug("Discovery Job Run Key: "+str(discoveryJobKey))

    # Get component ID for newly created component
    componentKey = getComponentKey(source,templateDBKey,objName)
    if componentKey == 0:
        printError("Unable to get component key for %s" % objName)
        return 0

    # Create a BLPackage from the component
    packageKey = doCreateBLPackage(objName,depotGroupId,str(componentKey))
    printDebug("BLPackage key: %s" % str(packageKey))

    deleteCodeRepository(source,basePath)
    printInfo(" ****** Package creation complete ****** \n")

    return packageKey

# END def doPackage()

try:
        opts, args = getopt.getopt(sys.argv[1:], "v:p:t:n:r:s:c:i:e")
except getopt.GetoptError:
        usage()

vendor = ''
platform = ''
depTier = ''
appName = ''
appVersion = ''
sibVer = ''
source = ''
repository = ''
assets = ''

for opt, arg in opts:
        if opt == '-v':
                vendor = arg
        elif opt == '-p':
                platform = arg
        elif opt == '-t':
                depTier = arg
        elif opt == '-n':
                appName = arg
        elif opt == '-r':
                appVersion = arg
        elif opt == '-s':
                sibVer = arg
        elif opt == '-c':
                source = arg
        elif opt == '-i':
                repository = arg
        elif opt == '-e':
                assets = arg

doPackage(vendor,platform,depTier,appName,appVersion,sibVer,source,repository,assets)
